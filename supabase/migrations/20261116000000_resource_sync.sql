-- Resource sync: players, server-side balances and the idempotent transaction ledger.
-- Clients may only insert their own transactions; balances are recalculated by trigger.

create table public.players (
  id uuid primary key references auth.users(id) on delete cascade,
  locale text not null default 'es',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.player_resources (
  player_id uuid primary key references public.players(id) on delete cascade,
  coins integer not null default 0 check (coins >= 0),
  nature integer not null default 0 check (nature >= 0),
  xp integer not null default 0 check (xp >= 0),
  updated_at timestamptz not null default now()
);

create table public.resource_transactions (
  id bigint generated always as identity primary key,
  player_id uuid not null references public.players(id) on delete cascade,
  idem_key text not null check (char_length(idem_key) between 1 and 128),
  delta_coins integer not null default 0,
  delta_nature integer not null default 0,
  delta_xp integer not null default 0 check (delta_xp >= 0),
  reason text not null check (char_length(reason) <= 32),
  client_at timestamptz not null,
  server_at timestamptz not null default now(),
  unique (player_id, idem_key)
);
create index resource_transactions_recent on public.resource_transactions (player_id, server_at desc);

create function public.create_player_for_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.players (id) values (new.id);
  insert into public.player_resources (player_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_player_for_user();

create function public.apply_resource_transaction() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.player_resources
     set coins = greatest(0, coins + new.delta_coins),
         nature = greatest(0, nature + new.delta_nature),
         xp = xp + new.delta_xp,
         updated_at = now()
   where player_id = new.player_id;
  return new;
end;
$$;

create trigger on_resource_transaction_inserted
  after insert on public.resource_transactions
  for each row execute function public.apply_resource_transaction();

alter table public.players enable row level security;
alter table public.player_resources enable row level security;
alter table public.resource_transactions enable row level security;

create policy players_select_own on public.players
  for select to authenticated using (id = (select auth.uid()));

create policy player_resources_select_own on public.player_resources
  for select to authenticated using (player_id = (select auth.uid()));

create policy resource_transactions_select_own on public.resource_transactions
  for select to authenticated using (player_id = (select auth.uid()));

create policy resource_transactions_insert_own on public.resource_transactions
  for insert to authenticated with check (player_id = (select auth.uid()));

revoke all on public.players, public.player_resources, public.resource_transactions from anon;
revoke update, delete on public.resource_transactions from authenticated;
revoke insert, update, delete on public.players, public.player_resources from authenticated;
