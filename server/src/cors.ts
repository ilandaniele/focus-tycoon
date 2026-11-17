import { HttpError } from "./http";

const PREFLIGHT_MAX_AGE_SECONDS = "86400";

export function allowedOrigin(request: Request, allowList: string): string | null {
  const origin = request.headers.get("Origin");
  if (!origin) return null;
  return allowList.split(",").map((entry) => entry.trim()).includes(origin) ? origin : null;
}

export function preflight(request: Request, allowList: string): Response {
  if (!allowedOrigin(request, allowList)) throw new HttpError(403, "origin_not_allowed");
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Methods": "GET, POST",
      "Access-Control-Allow-Headers": "Authorization, Content-Type",
      "Access-Control-Max-Age": PREFLIGHT_MAX_AGE_SECONDS,
    },
  });
}

export function withCors(response: Response, origin: string | null): Response {
  if (!origin) return response;
  response.headers.set("Access-Control-Allow-Origin", origin);
  response.headers.set("Access-Control-Expose-Headers", "X-Request-Id");
  response.headers.set("Vary", "Origin");
  return response;
}
