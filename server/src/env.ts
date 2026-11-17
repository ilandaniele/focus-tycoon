export interface Env {
  DB: D1Database;
  SIGNUP_LIMITER: RateLimit;
  SYNC_LIMITER: RateLimit;
  IP_LIMITER: RateLimit;
}
