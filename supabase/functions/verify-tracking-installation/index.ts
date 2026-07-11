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
    Deno.env.get("NOVA_VERIFY_ALLOWED_ORIGINS"),
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

function requiredTrimmedHeader(
  request: Request,
  name: string,
  maxLength: number,
): string {
  const value = request.headers.get(name);
  if (value == null) {
    throw new HttpError(401, "unauthorized", "Invalid installation credentials.");
  }

  const normalized = value.trim();
  if (normalized.length === 0 || normalized.length > maxLength) {
    throw new HttpError(401, "unauthorized", "Invalid installation credentials.");
  }

  return normalized;
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

async function loadInstallation(publicShopId: string) {
  const { url, serviceRoleKey } = supabaseConfig();
  const response = await fetch(
    `${url}/rest/v1/tracking_installations?public_shop_id=eq.${
      encodeURIComponent(publicShopId)
    }&is_enabled=eq.true&select=installation_secret_hash&limit=1`,
    {
      headers: {
        "apikey": serviceRoleKey,
        "authorization": `Bearer ${serviceRoleKey}`,
        "content-type": "application/json",
      },
    },
  );

  if (!response.ok) {
    throw new HttpError(500, "backend_error", "Verification failed.");
  }

  const rows = await response.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
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
    const publicShopId = requiredTrimmedHeader(request, "x-nova-shop-id", 128);
    const installationSecret = requiredTrimmedHeader(
      request,
      "x-nova-installation-secret",
      512,
    );

    const installation = await loadInstallation(publicShopId);
    if (!installation) {
      throw new HttpError(
        401,
        "unauthorized",
        "Invalid installation credentials.",
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
        401,
        "unauthorized",
        "Invalid installation credentials.",
      );
    }

    return jsonResponse(request, 200, { ok: true });
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
      message: "Verification failed.",
    });
  }
});
