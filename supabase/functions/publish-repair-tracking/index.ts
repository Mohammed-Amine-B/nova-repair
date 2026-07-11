const supportedContractVersion = 1;

const allowedStatuses = new Set([
  "received",
  "diagnosing",
  "waiting_for_customer_approval",
  "waiting_for_part",
  "repairing",
  "ready_for_pickup",
  "delivered",
  "cancelled",
]);

type PublishPayload = {
  contractVersion?: unknown;
  trackingToken?: unknown;
  shop?: {
    publicId?: unknown;
    name?: unknown;
    subtitle?: unknown;
  };
  repair?: {
    code?: unknown;
    device?: unknown;
    status?: unknown;
    customerMessage?: unknown;
    receivedAt?: unknown;
    updatedAt?: unknown;
  };
};

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

function jsonResponse(
  request: Request,
  status: number,
  body: Record<string, unknown>,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders(request),
    },
  });
}

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("origin");
  const allowedOrigins = parseAllowedOrigins(
    Deno.env.get("NOVA_PUBLISH_ALLOWED_ORIGINS"),
  );

  if (!origin || !isOriginAllowed(origin, allowedOrigins)) {
    return { "vary": "Origin" };
  }

  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers":
      "content-type, x-nova-shop-id, x-nova-installation-secret",
    "vary": "Origin",
  };
}

function parseAllowedOrigins(value: string | undefined): string[] {
  return (value ?? "")
    .split(",")
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

function isOriginAllowed(origin: string, allowedOrigins: string[]): boolean {
  return allowedOrigins.includes(origin) || allowedOrigins.includes("*");
}

function requiredTrimmedString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string {
  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_payload", `${fieldName} is required.`);
  }

  const normalized = value.trim();
  if (normalized.length === 0) {
    throw new HttpError(400, "invalid_payload", `${fieldName} is required.`);
  }

  if (normalized.length > maxLength) {
    throw new HttpError(400, "invalid_payload", `${fieldName} is too long.`);
  }

  return normalized;
}

function optionalTrimmedString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string | null {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_payload", `${fieldName} is invalid.`);
  }

  const normalized = value.trim();
  if (normalized.length === 0) {
    return null;
  }

  if (normalized.length > maxLength) {
    throw new HttpError(400, "invalid_payload", `${fieldName} is too long.`);
  }

  return normalized;
}

function requiredTimestamp(value: unknown, fieldName: string): string {
  if (typeof value !== "string") {
    throw new HttpError(400, "invalid_payload", `${fieldName} is required.`);
  }

  const timestamp = new Date(value);
  if (Number.isNaN(timestamp.getTime())) {
    throw new HttpError(400, "invalid_payload", `${fieldName} is invalid.`);
  }

  return timestamp.toISOString();
}

function validatePayload(payload: PublishPayload) {
  if (payload.contractVersion !== supportedContractVersion) {
    throw new HttpError(
      400,
      "unsupported_contract_version",
      "Unsupported tracking contract version.",
    );
  }

  const trackingToken = requiredTrimmedString(
    payload.trackingToken,
    "trackingToken",
    256,
  );

  const publicShopId = requiredTrimmedString(
    payload.shop?.publicId,
    "shop.publicId",
    128,
  );

  const shopName = requiredTrimmedString(payload.shop?.name, "shop.name", 160);
  const shopSubtitle = optionalTrimmedString(
    payload.shop?.subtitle,
    "shop.subtitle",
    240,
  );

  const repairCode = requiredTrimmedString(
    payload.repair?.code,
    "repair.code",
    100,
  );
  const deviceDisplayName = requiredTrimmedString(
    payload.repair?.device,
    "repair.device",
    300,
  );
  const status = requiredTrimmedString(
    payload.repair?.status,
    "repair.status",
    64,
  );

  if (!allowedStatuses.has(status)) {
    throw new HttpError(400, "invalid_payload", "repair.status is invalid.");
  }

  return {
    trackingToken,
    publicShopId,
    shopName,
    shopSubtitle,
    repairCode,
    deviceDisplayName,
    status,
    customerMessage: optionalTrimmedString(
      payload.repair?.customerMessage,
      "repair.customerMessage",
      2000,
    ),
    receivedAt: requiredTimestamp(payload.repair?.receivedAt, "repair.receivedAt"),
    sourceUpdatedAt: requiredTimestamp(
      payload.repair?.updatedAt,
      "repair.updatedAt",
    ),
  };
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );

  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) {
    return false;
  }

  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }

  return difference === 0;
}

function supabaseConfig() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new HttpError(
      500,
      "server_not_configured",
      "Tracking backend is not configured.",
    );
  }

  return { url, serviceRoleKey };
}

async function supabaseRest(
  path: string,
  init: RequestInit = {},
): Promise<Response> {
  const { url, serviceRoleKey } = supabaseConfig();
  return fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: {
      "apikey": serviceRoleKey,
      "authorization": `Bearer ${serviceRoleKey}`,
      "content-type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

async function loadInstallation(publicShopId: string) {
  const response = await supabaseRest(
    `tracking_installations?public_shop_id=eq.${
      encodeURIComponent(publicShopId)
    }&is_enabled=eq.true&select=public_shop_id,installation_secret_hash&limit=1`,
  );

  if (!response.ok) {
    throw new HttpError(500, "backend_error", "Authentication lookup failed.");
  }

  const rows = await response.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

async function publishSnapshot(snapshot: ReturnType<typeof validatePayload>) {
  const response = await supabaseRest("rpc/publish_public_repair_tracking", {
    method: "POST",
    body: JSON.stringify({
      p_tracking_token: snapshot.trackingToken,
      p_contract_version: supportedContractVersion,
      p_public_shop_id: snapshot.publicShopId,
      p_shop_name: snapshot.shopName,
      p_shop_subtitle: snapshot.shopSubtitle,
      p_repair_code: snapshot.repairCode,
      p_device_display_name: snapshot.deviceDisplayName,
      p_status: snapshot.status,
      p_customer_message: snapshot.customerMessage,
      p_received_at: snapshot.receivedAt,
      p_source_updated_at: snapshot.sourceUpdatedAt,
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    if (error?.code === "42501") {
      throw new HttpError(
        409,
        "ownership_conflict",
        "Tracking token belongs to another shop.",
      );
    }

    throw new HttpError(500, "backend_error", "Snapshot publish failed.");
  }

  return await response.json() as "published" | "already_current" | "ignored_stale";
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }

  if (request.method !== "POST") {
    return jsonResponse(request, 405, {
      ok: false,
      error: "method_not_allowed",
    });
  }

  try {
    const publicShopIdHeader = requiredTrimmedString(
      request.headers.get("x-nova-shop-id"),
      "X-Nova-Shop-Id",
      128,
    );
    const installationSecret = requiredTrimmedString(
      request.headers.get("x-nova-installation-secret"),
      "X-Nova-Installation-Secret",
      512,
    );

    let parsedBody: PublishPayload;
    try {
      parsedBody = await request.json();
    } catch (_) {
      throw new HttpError(400, "invalid_json", "Request body must be valid JSON.");
    }

    const snapshot = validatePayload(parsedBody);
    if (snapshot.publicShopId !== publicShopIdHeader) {
      throw new HttpError(
        403,
        "invalid_authentication",
        "Invalid installation authentication.",
      );
    }

    const installation = await loadInstallation(publicShopIdHeader);
    if (!installation) {
      throw new HttpError(
        403,
        "invalid_authentication",
        "Invalid installation authentication.",
      );
    }

    const suppliedHash = await sha256Hex(installationSecret);
    if (
      !constantTimeEqual(
        suppliedHash,
        String(installation.installation_secret_hash),
      )
    ) {
      throw new HttpError(
        403,
        "invalid_authentication",
        "Invalid installation authentication.",
      );
    }

    const result = await publishSnapshot(snapshot);
    return jsonResponse(request, 200, { ok: true, result });
  } catch (error) {
    if (error instanceof HttpError) {
      return jsonResponse(request, error.status, {
        ok: false,
        error: error.code,
        message: error.message,
      });
    }

    return jsonResponse(request, 500, {
      ok: false,
      error: "backend_error",
      message: "Tracking publish failed.",
    });
  }
});
