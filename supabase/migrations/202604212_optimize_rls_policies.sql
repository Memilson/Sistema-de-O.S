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
