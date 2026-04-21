create table if not exists public.clientes (
  id text primary key,
  "userId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  nome text not null,
  "cpfCnpj" text,
  email text,
  telefone text,
  "createdAt" timestamptz not null default now()
);

create table if not exists public.ordens_servico (
  id text primary key,
  "userId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "clienteId" text not null references public.clientes(id) on delete cascade,
  "clienteNome" text not null,
  descricao text,
  valor numeric(12, 2) not null default 0,
  status text not null default 'Em aberto',
  "fotoAntesPath" text,
  "fotoDepoisPath" text,
  "assinaturaBase64" text,
  "createdAt" timestamptz not null default now()
);

alter table public.clientes enable row level security;
alter table public.ordens_servico enable row level security;

drop policy if exists "clientes_select_own" on public.clientes;
create policy "clientes_select_own"
  on public.clientes for select
  to authenticated
  using ((select auth.uid()) = "userId");

drop policy if exists "clientes_insert_own" on public.clientes;
create policy "clientes_insert_own"
  on public.clientes for insert
  to authenticated
  with check ((select auth.uid()) = "userId");

drop policy if exists "clientes_update_own" on public.clientes;
create policy "clientes_update_own"
  on public.clientes for update
  to authenticated
  using ((select auth.uid()) = "userId")
  with check ((select auth.uid()) = "userId");

drop policy if exists "clientes_delete_own" on public.clientes;
create policy "clientes_delete_own"
  on public.clientes for delete
  to authenticated
  using ((select auth.uid()) = "userId");

drop policy if exists "ordens_servico_select_own" on public.ordens_servico;
create policy "ordens_servico_select_own"
  on public.ordens_servico for select
  to authenticated
  using ((select auth.uid()) = "userId");

drop policy if exists "ordens_servico_insert_own" on public.ordens_servico;
create policy "ordens_servico_insert_own"
  on public.ordens_servico for insert
  to authenticated
  with check ((select auth.uid()) = "userId");

drop policy if exists "ordens_servico_update_own" on public.ordens_servico;
create policy "ordens_servico_update_own"
  on public.ordens_servico for update
  to authenticated
  using ((select auth.uid()) = "userId")
  with check ((select auth.uid()) = "userId");

drop policy if exists "ordens_servico_delete_own" on public.ordens_servico;
create policy "ordens_servico_delete_own"
  on public.ordens_servico for delete
  to authenticated
  using ((select auth.uid()) = "userId");

create index if not exists clientes_user_id_idx on public.clientes ("userId");
create index if not exists ordens_servico_user_id_idx on public.ordens_servico ("userId");
create index if not exists ordens_servico_cliente_id_idx on public.ordens_servico ("clienteId");
