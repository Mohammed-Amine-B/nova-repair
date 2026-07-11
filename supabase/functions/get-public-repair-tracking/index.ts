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
    Deno.env.get("NOVA_PUBLIC_TRACKING_ALLOWED_ORIGINS"),
  );

  if (!origin || !isOriginAllowed(origin, allowedOrigins)) {
    return { "vary": "Origin" };
  }

  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "GET, OPTIONS",
    "access-control-allow-headers": "content-type",
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

function requiredToken(request: Request): string {
  const url = new URL(request.url);
  const token = (url.searchParams.get("token") ?? "").trim();

  if (token.length === 0 || token.length > 256) {
    throw new HttpError(404, "not_found", "Repair tracking was not found.");
  }

  return token;
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

async function supabaseRest(path: string): Promise<Response> {
  const { url, serviceRoleKey } = supabaseConfig();
  return fetch(`${url}/rest/v1/${path}`, {
    headers: {
      "apikey": serviceRoleKey,
      "authorization": `Bearer ${serviceRoleKey}`,
      "content-type": "application/json",
    },
  });
}

async function loadTrackingSnapshot(token: string) {
  const selectedColumns = [
    "contract_version",
    "shop_name",
    "shop_subtitle",
    "repair_code",
    "device_display_name",
    "status",
    "customer_message",
    "received_at",
    "source_updated_at",
  ].join(",");

  const response = await supabaseRest(
    `public_repair_tracking?tracking_token=eq.${
      encodeURIComponent(token)
    }&select=${selectedColumns}&limit=1`,
  );

  if (!response.ok) {
    throw new HttpError(500, "backend_error", "Tracking lookup failed.");
  }

  const rows = await response.json();
  return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
}

function publicSnapshotResponse(row: Record<string, unknown>) {
  return {
    contractVersion: row.contract_version,
    shop: {
      name: row.shop_name,
      subtitle: row.shop_subtitle,
    },
    repair: {
      code: row.repair_code,
      device: row.device_display_name,
      status: row.status,
      customerMessage: row.customer_message,
      receivedAt: row.received_at,
      updatedAt: row.source_updated_at,
    },
  };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(request) });
  }

  if (request.method !== "GET") {
    return jsonResponse(request, 405, {
      ok: false,
      error: "method_not_allowed",
    });
  }

  try {
    const token = requiredToken(request);
    const snapshot = await loadTrackingSnapshot(token);

    if (!snapshot) {
      throw new HttpError(404, "not_found", "Repair tracking was not found.");
    }

    return jsonResponse(request, 200, {
      ok: true,
      data: publicSnapshotResponse(snapshot),
    });
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
      message: "Tracking lookup failed.",
    });
  }
});
