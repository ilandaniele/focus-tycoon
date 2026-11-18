import { env, SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import { RETENTION_DAYS } from "../src/retention";

const BASE = "https://api.test";

type Session = { player_id: string; token: string };

let ipCounter = 0;

function nextIp(): string {
  ipCounter += 1;
  return `10.0.${Math.floor(ipCounter / 250)}.${ipCounter % 250}`;
}

async function signup(ip = nextIp()): Promise<Session> {
  const response = await SELF.fetch(`${BASE}/v1/players`, { method: "POST", headers: { "CF-Connecting-IP": ip } });
  expect(response.status).toBe(201);
  return response.json();
}

function transaction(idemKey: string, overrides: Record<string, unknown> = {}) {
  return {
    idem_key: idemKey,
    delta_coins: 10,
    delta_nature: 2,
    delta_xp: 5,
    reason: "focus_session",
    client_at: "2026-11-17T10:00:00Z",
    ...overrides,
  };
}

function push(token: string, body: unknown, ip = nextIp()): Promise<Response> {
  return SELF.fetch(`${BASE}/v1/transactions`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", "CF-Connecting-IP": ip },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

async function balance(token: string): Promise<Record<string, number>> {
  const response = await SELF.fetch(`${BASE}/v1/resources`, {
    headers: { Authorization: `Bearer ${token}`, "CF-Connecting-IP": nextIp() },
  });
  expect(response.status).toBe(200);
  return response.json();
}

describe("POST /v1/players", () => {
  it("returns a player id and a token with a zero balance", async () => {
    const session = await signup();
    expect(session.player_id).toMatch(/^[0-9a-f-]{36}$/);
    expect(session.token.length).toBeGreaterThanOrEqual(40);
    expect(await balance(session.token)).toEqual({ coins: 0, nature: 0, xp: 0 });
  });

  it("stores only the token hash", async () => {
    const session = await signup();
    const row = await env.DB.prepare("SELECT token_hash FROM players WHERE id = ?").bind(session.player_id).first<{ token_hash: string }>();
    expect(row?.token_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(row?.token_hash).not.toBe(session.token);
  });

  it("rate limits signups per IP", async () => {
    const ip = "192.0.2.77";
    const statuses: number[] = [];
    for (let attempt = 0; attempt < 7; attempt += 1) {
      const response = await SELF.fetch(`${BASE}/v1/players`, { method: "POST", headers: { "CF-Connecting-IP": ip } });
      statuses.push(response.status);
    }
    expect(statuses).toContain(429);
  });

  it("rate limits signups per IPv6 /64 prefix", async () => {
    const statuses: number[] = [];
    for (let host = 1; host <= 7; host += 1) {
      const response = await SELF.fetch(`${BASE}/v1/players`, {
        method: "POST",
        headers: { "CF-Connecting-IP": `2001:db8:77:1::${host}` },
      });
      statuses.push(response.status);
    }
    expect(statuses).toContain(429);
  });
});

describe("POST /v1/transactions", () => {
  it("applies transactions to the balance", async () => {
    const { token } = await signup();
    const response = await push(token, { transactions: [transaction("a"), transaction("b", { delta_coins: -5 })] });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ received: 2, accepted: 2 });
    expect(await balance(token)).toEqual({ coins: 5, nature: 4, xp: 10 });
  });

  it("ignores repeated idempotency keys", async () => {
    const { token } = await signup();
    await push(token, { transactions: [transaction("same")] });
    const response = await push(token, { transactions: [transaction("same"), transaction("same")] });
    expect(await response.json()).toEqual({ received: 2, accepted: 0 });
    expect(await balance(token)).toEqual({ coins: 10, nature: 2, xp: 5 });
  });

  it("clamps spending at zero", async () => {
    const { token } = await signup();
    await push(token, { transactions: [transaction("spend", { delta_coins: -50, delta_nature: -50 })] });
    expect(await balance(token)).toEqual({ coins: 0, nature: 0, xp: 5 });
  });

  it("keeps players isolated when they reuse keys", async () => {
    const first = await signup();
    const second = await signup();
    await push(first.token, { transactions: [transaction("shared")] });
    await push(second.token, { transactions: [transaction("shared", { delta_coins: 1 })] });
    expect((await balance(first.token)).coins).toBe(10);
    expect((await balance(second.token)).coins).toBe(1);
  });

  it("rejects missing and unknown tokens", async () => {
    const missing = await SELF.fetch(`${BASE}/v1/transactions`, { method: "POST", body: "{}" });
    expect(missing.status).toBe(401);
    const unknown = await push("x".repeat(43), { transactions: [transaction("a")] });
    expect(unknown.status).toBe(401);
    expect(await unknown.json()).toMatchObject({ error: "unauthorized", request_id: expect.any(String) });
  });

  it.each([
    ["malformed json", "{nope", "invalid_json"],
    ["empty batch", { transactions: [] }, "invalid_body"],
    ["extra fields", { transactions: [transaction("a", { player_id: "someone-else" })] }, "invalid_body"],
    ["negative xp", { transactions: [transaction("a", { delta_xp: -1 })] }, "invalid_body"],
    ["bad timestamp", { transactions: [transaction("a", { client_at: "yesterday" })] }, "invalid_body"],
    ["fractional timestamp", { transactions: [transaction("a", { client_at: `2026-11-17T10:00:00.${"1".repeat(5000)}Z` })] }, "invalid_body"],
    ["oversized batch", { transactions: Array.from({ length: 101 }, (_, index) => transaction(`k${index}`)) }, "invalid_body"],
  ])("rejects %s with 400", async (_name, body, code) => {
    const { token } = await signup();
    const response = await push(token, body);
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({ error: code });
  });

  it("rejects bodies over 64 KB with 413", async () => {
    const { token } = await signup();
    const response = await push(token, JSON.stringify({ padding: "x".repeat(70 * 1024) }));
    expect(response.status).toBe(413);
  });

  it("rejects multibyte bodies over 64 KB with 413", async () => {
    const { token } = await signup();
    const response = await push(token, JSON.stringify({ padding: "é".repeat(40 * 1024) }));
    expect(response.status).toBe(413);
  });

  it("rejects a declared Content-Length over 64 KB before reading the body", async () => {
    const { token } = await signup();
    const response = await SELF.fetch(`${BASE}/v1/transactions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Length": String(70 * 1024), "CF-Connecting-IP": nextIp() },
      body: "{}",
    });
    expect(response.status).toBe(413);
  });

  it("rate limits pushes per player", async () => {
    const { token } = await signup();
    const statuses: number[] = [];
    for (let attempt = 0; attempt < 32; attempt += 1) {
      statuses.push((await push(token, { transactions: [transaction(`r${attempt}`)] })).status);
    }
    expect(statuses).toContain(429);
  });
});

describe("routing and headers", () => {
  it("returns 404 for unknown paths", async () => {
    const response = await SELF.fetch(`${BASE}/v1/nope`, { headers: { Origin: "https://evil.example" } });
    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({ error: "not_found" });
  });

  it("returns 405 for wrong methods", async () => {
    const response = await SELF.fetch(`${BASE}/v1/players`);
    expect(response.status).toBe(405);
  });

  it("rate limits authenticated requests per IP before touching the database", async () => {
    const ip = "198.51.100.9";
    const statuses: number[] = [];
    for (let attempt = 0; attempt < 62; attempt += 1) {
      const response = await SELF.fetch(`${BASE}/v1/resources`, {
        headers: { Authorization: `Bearer ${"x".repeat(43)}`, "CF-Connecting-IP": ip },
      });
      statuses.push(response.status);
    }
    expect(statuses).toContain(429);
  });

  it("sends a request id header on every response", async () => {
    const session = await signup();
    const ok = await SELF.fetch(`${BASE}/v1/resources`, {
      headers: { Authorization: `Bearer ${session.token}`, "CF-Connecting-IP": nextIp() },
    });
    const missing = await SELF.fetch(`${BASE}/v1/nope`);
    expect(ok.headers.get("X-Request-Id")).toMatch(/^[0-9a-f-]{36}$/);
    expect(((await missing.json()) as { request_id: string }).request_id).toBe(missing.headers.get("X-Request-Id"));
  });

  it("sends security headers and no CORS headers without an allowed origin", async () => {
    const response = await SELF.fetch(`${BASE}/v1/nope`, { headers: { Origin: "https://evil.example" } });
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(response.headers.get("Cache-Control")).toBe("no-store");
    expect(response.headers.get("Content-Security-Policy")).toContain("default-src 'none'");
    expect(response.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });
});

describe("CORS for the web build", () => {
  const ORIGIN = "https://focus-tycoon.ilandaniele.workers.dev";

  it("answers preflight from an allowed origin", async () => {
    const response = await SELF.fetch(`${BASE}/v1/transactions`, {
      method: "OPTIONS",
      headers: { Origin: ORIGIN, "Access-Control-Request-Method": "POST", "CF-Connecting-IP": nextIp() },
    });
    expect(response.status).toBe(204);
    expect(response.headers.get("Access-Control-Allow-Origin")).toBe(ORIGIN);
    expect(response.headers.get("Access-Control-Allow-Headers")).toContain("Authorization");
    expect(response.headers.get("Vary")).toBe("Origin");
  });

  it("rejects preflight from an unknown origin", async () => {
    const response = await SELF.fetch(`${BASE}/v1/transactions`, {
      method: "OPTIONS",
      headers: { Origin: "https://evil.example", "Access-Control-Request-Method": "POST", "CF-Connecting-IP": nextIp() },
    });
    expect(response.status).toBe(403);
    expect(response.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });

  it("adds the allow origin header to real responses", async () => {
    const response = await SELF.fetch(`${BASE}/v1/players`, {
      method: "POST",
      headers: { Origin: ORIGIN, "CF-Connecting-IP": nextIp() },
    });
    expect(response.status).toBe(201);
    expect(response.headers.get("Access-Control-Allow-Origin")).toBe(ORIGIN);
  });
});

function deletePlayer(token: string | null): Promise<Response> {
  const headers: Record<string, string> = { "CF-Connecting-IP": nextIp() };
  if (token) headers.Authorization = `Bearer ${token}`;
  return SELF.fetch(`${BASE}/v1/players`, { method: "DELETE", headers });
}

async function countRows(table: string, playerColumn: string, playerId: string): Promise<number> {
  const row = await env.DB.prepare(`SELECT count(*) AS total FROM ${table} WHERE ${playerColumn} = ?`).bind(playerId).first<{ total: number }>();
  return row?.total ?? 0;
}

describe("DELETE /v1/players", () => {
  it("deletes the player, balance and ledger", async () => {
    const session = await signup();
    expect((await push(session.token, { transactions: [transaction("a")] })).status).toBe(200);
    const response = await deletePlayer(session.token);
    expect(response.status).toBe(204);
    expect(await countRows("players", "id", session.player_id)).toBe(0);
    expect(await countRows("player_resources", "player_id", session.player_id)).toBe(0);
    expect(await countRows("resource_transactions", "player_id", session.player_id)).toBe(0);
    const after = await SELF.fetch(`${BASE}/v1/resources`, {
      headers: { Authorization: `Bearer ${session.token}`, "CF-Connecting-IP": nextIp() },
    });
    expect(after.status).toBe(401);
  });

  it("deletes only the caller", async () => {
    const caller = await signup();
    const other = await signup();
    await push(other.token, { transactions: [transaction("a")] });
    expect((await deletePlayer(caller.token)).status).toBe(204);
    expect((await balance(other.token)).coins).toBe(10);
  });

  it("rejects missing and unknown tokens", async () => {
    expect((await deletePlayer(null)).status).toBe(401);
    expect((await deletePlayer("x".repeat(43))).status).toBe(401);
  });

  it("allows DELETE in preflight", async () => {
    const response = await SELF.fetch(`${BASE}/v1/players`, {
      method: "OPTIONS",
      headers: {
        Origin: "https://focus-tycoon.ilandaniele.workers.dev",
        "Access-Control-Request-Method": "DELETE",
        "CF-Connecting-IP": nextIp(),
      },
    });
    expect(response.headers.get("Access-Control-Allow-Methods")).toContain("DELETE");
  });
});

describe("inactive player purge", () => {
  const DAY_MS = 24 * 60 * 60 * 1000;

  async function setLastActivity(playerId: string, at: number): Promise<void> {
    await env.DB.prepare("UPDATE player_resources SET updated_at = ? WHERE player_id = ?").bind(at, playerId).run();
  }

  it("a new signup deletes players idle for longer than the retention window and keeps the rest", async () => {
    const now = Date.now();
    const idle = await signup();
    const active = await signup();
    await setLastActivity(idle.player_id, now - (RETENTION_DAYS + 1) * DAY_MS);
    await setLastActivity(active.player_id, now - (RETENTION_DAYS - 1) * DAY_MS);
    await signup();
    expect(await countRows("players", "id", idle.player_id)).toBe(0);
    expect(await countRows("players", "id", active.player_id)).toBe(1);
  });
});
