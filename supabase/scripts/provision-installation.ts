type ProvisioningConfig = {
  supabaseUrl: string;
  serviceRoleKey: string;
  publicShopId: string;
};

function readConfig(): ProvisioningConfig {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const publicShopId = (
    Deno.args[0] ??
      Deno.env.get("PUBLIC_SHOP_ID") ??
      ""
  ).trim();

  if (!supabaseUrl) {
    throw new Error("SUPABASE_URL is required.");
  }

  if (!serviceRoleKey) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is required.");
  }

  if (publicShopId.length === 0 || publicShopId.length > 128) {
    throw new Error("PUBLIC_SHOP_ID must be 1-128 characters.");
  }

  return { supabaseUrl, serviceRoleKey, publicShopId };
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function generateInstallationSecret(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return base64Url(bytes);
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

async function createInstallation(
  config: ProvisioningConfig,
  installationSecretHash: string,
) {
  const response = await fetch(
    `${config.supabaseUrl}/rest/v1/tracking_installations`,
    {
      method: "POST",
      headers: {
        "apikey": config.serviceRoleKey,
        "authorization": `Bearer ${config.serviceRoleKey}`,
        "content-type": "application/json",
        "prefer": "return=minimal",
      },
      body: JSON.stringify({
        public_shop_id: config.publicShopId,
        installation_secret_hash: installationSecretHash,
        is_enabled: true,
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Installation provisioning failed (${response.status}). ${body}`,
    );
  }
}

const config = readConfig();
const installationSecret = generateInstallationSecret();
const installationSecretHash = await sha256Hex(installationSecret);

await createInstallation(config, installationSecretHash);

console.log("Nova Repair tracking installation provisioned.");
console.log("");
console.log(`Public shop ID: ${config.publicShopId}`);
console.log(`Installation secret: ${installationSecret}`);
console.log("");
console.log("Store this installation secret securely. It is shown only once.");
