import type { PublicRepairTrackingData, PublicTrackingResponse } from "./types";

export type TrackingLookupResult =
  | {
      state: "found";
      data: PublicRepairTrackingData;
    }
  | {
      state: "not-found";
    }
  | {
      state: "error";
    };

export async function getPublicRepairTracking(
  token: string,
): Promise<TrackingLookupResult> {
  const trimmedToken = token.trim();

  if (trimmedToken.length === 0) {
    return { state: "not-found" };
  }

  const functionUrl = process.env.NOVA_PUBLIC_TRACKING_FUNCTION_URL?.trim();

  if (!functionUrl) {
    return { state: "error" };
  }

  let response: Response;

  try {
    const url = new URL(functionUrl);
    url.searchParams.set("token", trimmedToken);

    response = await fetch(url, {
      method: "GET",
      headers: {
        accept: "application/json",
      },
      cache: "no-store",
    });
  } catch {
    return { state: "error" };
  }

  if (response.status === 404) {
    return { state: "not-found" };
  }

  if (!response.ok) {
    return { state: "error" };
  }

  let body: PublicTrackingResponse;

  try {
    body = (await response.json()) as PublicTrackingResponse;
  } catch {
    return { state: "error" };
  }

  if (!body.ok) {
    return body.error === "not_found"
      ? { state: "not-found" }
      : { state: "error" };
  }

  return { state: "found", data: body.data };
}
