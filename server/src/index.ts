import type { Env } from "./env";
import { errorResponse, HttpError } from "./http";
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
    try {
      return await route(request, env);
    } catch (error) {
      if (error instanceof HttpError) return errorResponse(error.status, error.code, requestId);
      console.error(JSON.stringify({ request_id: requestId, error: String(error) }));
      return errorResponse(500, "internal_error", requestId);
    }
  },
} satisfies ExportedHandler<Env>;

function route(request: Request, env: Env): Promise<Response> {
  const methods = ROUTES[new URL(request.url).pathname];
  if (!methods) throw new HttpError(404, "not_found");
  const handler = methods[request.method];
  if (!handler) throw new HttpError(405, "method_not_allowed");
  return handler(request, env);
}
