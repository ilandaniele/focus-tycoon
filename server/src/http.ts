const SECURITY_HEADERS: Record<string, string> = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
};

export const MAX_BODY_BYTES = 64 * 1024;

export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
  ) {
    super(code);
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: SECURITY_HEADERS });
}

export function noContent(): Response {
  return new Response(null, { status: 204, headers: SECURITY_HEADERS });
}

export function errorResponse(status: number, code: string, requestId: string): Response {
  return json({ error: code, request_id: requestId }, status);
}

export async function readJson(request: Request): Promise<unknown> {
  if (Number(request.headers.get("Content-Length") ?? 0) > MAX_BODY_BYTES) throw new HttpError(413, "payload_too_large");
  const bytes = await request.arrayBuffer();
  if (bytes.byteLength > MAX_BODY_BYTES) throw new HttpError(413, "payload_too_large");
  const text = new TextDecoder().decode(bytes);
  try {
    return JSON.parse(text);
  } catch {
    throw new HttpError(400, "invalid_json");
  }
}

const IPV6_NETWORK_GROUPS = 4;

export function clientIp(request: Request): string {
  const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
  const mappedIpv4 = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/i.exec(ip);
  if (mappedIpv4) return mappedIpv4[1];
  return ip.includes(":") ? ipv6Network(ip) : ip;
}

function ipv6Network(ip: string): string {
  const [head, tail = ""] = ip.toLowerCase().split("::");
  const headGroups = head ? head.split(":") : [];
  const tailGroups = ip.includes("::") && tail ? tail.split(":") : [];
  const missing = Array(Math.max(0, 8 - headGroups.length - tailGroups.length)).fill("0");
  return [...headGroups, ...missing, ...tailGroups].slice(0, IPV6_NETWORK_GROUPS).join(":") + "::/64";
}
