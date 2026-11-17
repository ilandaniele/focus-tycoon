import type { Env } from "./env";
import { clientIp, errorResponse, HttpError } from "./http";
import { createPlayer } from "./routes/players";
import { getResources } from "./routes/resources";
import { pushTransactions } from "./routes/transactions";

type Handler = (request: Request, env: Env) => Promise<Response>;

const ROUTES: Record<string, Record<string, Handler>> = {
  "/v1/players": { POST: createPlayer },
  "/v1/transactions": { POST: pushTransactions },
  "/v1/resources": { GET: getResources },
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const requestId = crypto.randomUUID();
    const response = await handle(request, env, requestId);
    response.headers.set("X-Request-Id", requestId);
    return response;
  },
} satisfies ExportedHandler<Env>;

async function handle(request: Request, env: Env, requestId: string): Promise<Response> {
  try {
    return await route(request, env);
  } catch (error) {
    if (error instanceof HttpError) {
      console.warn(JSON.stringify({ request_id: requestId, status: error.status, error: error.code }));
      return errorResponse(error.status, error.code, requestId);
    }
    console.error(JSON.stringify({ request_id: requestId, error: String(error) }));
    return errorResponse(500, "internal_error", requestId);
  }
}

async function route(request: Request, env: Env): Promise<Response> {
  const methods = ROUTES[new URL(request.url).pathname];
  if (!methods) throw new HttpError(404, "not_found");
  if (!Object.hasOwn(methods, request.method)) throw new HttpError(405, "method_not_allowed");
  const { success } = await env.IP_LIMITER.limit({ key: clientIp(request) });
  if (!success) throw new HttpError(429, "rate_limited");
  return methods[request.method](request, env);
}
