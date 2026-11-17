import type { D1Migration } from "cloudflare:test";
import type { Env as ProjectEnv } from "../src/env";

declare global {
  namespace Cloudflare {
    interface Env extends ProjectEnv {
      TEST_MIGRATIONS: D1Migration[];
    }
  }
}
