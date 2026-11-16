import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';

const migration = readFileSync(process.argv[2], 'utf8');
const db = new PGlite();
const U1 = '11111111-1111-1111-1111-111111111111';
const U2 = '22222222-2222-2222-2222-222222222222';
let failed = 0;

await db.exec(`
  create role anon nologin; create role authenticated nologin;
  create schema auth;
  create table auth.users (id uuid primary key);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema public, auth to anon, authenticated;
  grant execute on function auth.uid() to anon, authenticated;
  alter default privileges in schema public grant all on tables to anon, authenticated;
  alter default privileges in schema public grant all on sequences to anon, authenticated;
`);
await db.exec(migration);
await db.exec(`insert into auth.users values ('${U1}'), ('${U2}')`);

async function as(role, sub, sql) {
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${sub}', false); set role ${role}`);
  try { return await db.query(sql); } finally { await db.exec('reset role'); }
}

function tx(player, key, coins, nature = 0, xp = 0) {
  return `insert into public.resource_transactions (player_id, idem_key, delta_coins, delta_nature, delta_xp, reason, client_at)
    values ('${player}', '${key}', ${coins}, ${nature}, ${xp}, 'focus', now())
    on conflict (player_id, idem_key) do nothing`;
}

async function balance(player) {
  return (await db.query(`select coins, nature, xp from public.player_resources where player_id = '${player}'`)).rows[0];
}

async function check(name, fn) {
  try { await fn(); console.log('ok  ', name); }
  catch (e) { failed++; console.log('FAIL', name, '-', e.message); }
}

async function expectError(name, fn, pattern) {
  await check(name, async () => {
    try { await fn(); } catch (e) {
      if (pattern.test(e.message)) return;
      throw new Error('wrong error: ' + e.message);
    }
    throw new Error('no error raised');
  });
}

function equal(actual, expected) {
  if (JSON.stringify(actual) !== JSON.stringify(expected))
    throw new Error(`got ${JSON.stringify(actual)}, want ${JSON.stringify(expected)}`);
}

await check('signup creates player and zero balance', async () => {
  equal((await db.query(`select count(*)::int as n from public.players`)).rows[0].n, 2);
  equal(await balance(U1), { coins: 0, nature: 0, xp: 0 });
});

await check('own insert updates balance', async () => {
  await as('authenticated', U1, tx(U1, 'k1', 50, 5, 10));
  equal(await balance(U1), { coins: 50, nature: 5, xp: 10 });
});

await check('duplicate idem_key is ignored', async () => {
  await as('authenticated', U1, tx(U1, 'k1', 50, 5, 10));
  equal(await balance(U1), { coins: 50, nature: 5, xp: 10 });
});

await check('spend below zero clamps to zero', async () => {
  await as('authenticated', U1, tx(U1, 'k2', -80));
  equal((await balance(U1)).coins, 0);
});

await expectError('insert for another player is rejected', () => as('authenticated', U1, tx(U2, 'x', 999)), /row-level security/);
await expectError('negative xp is rejected', () => as('authenticated', U1, tx(U1, 'k3', 0, 0, -5)), /check constraint/);
await expectError('update own transaction is denied', () => as('authenticated', U1, `update public.resource_transactions set delta_coins = 999`), /permission denied/);
await expectError('delete own transaction is denied', () => as('authenticated', U1, `delete from public.resource_transactions`), /permission denied/);
await expectError('direct balance edit is denied', () => as('authenticated', U1, `update public.player_resources set coins = 999999`), /permission denied/);
await expectError('anon cannot read balances', () => as('anon', '', `select * from public.player_resources`), /permission denied/);

await check('select returns only own rows', async () => {
  await as('authenticated', U2, tx(U2, 'k1', 7));
  const rows = (await as('authenticated', U1, `select player_id from public.resource_transactions`)).rows;
  equal(rows.every(r => r.player_id === U1) && rows.length === 2, true);
  const resources = (await as('authenticated', U1, `select player_id from public.player_resources`)).rows;
  equal(resources.length, 1);
});

console.log(failed ? `${failed} failed` : 'all passed');
process.exit(failed ? 1 : 0);
