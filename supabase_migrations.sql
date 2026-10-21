-- ============================================================================
-- MIGRACIÓN COMPLETA SUPABASE — MANGOAR (MIS GASTOS PERSONALES MENSUALES)
-- Motor: PostgreSQL + Row Level Security (RLS) estricto por user_id
-- ============================================================================

create extension if not exists "pgcrypto";

-- 1. PERFILES / CONFIGURACIÓN DEL USUARIO (profiles)
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  sueldo_base numeric(14,2) not null default 2700000.00,
  divisor_horas integer not null default 200,
  recargo_hs_extra numeric(5,2) not null default 1.50,
  cotizacion_usd_default numeric(12,2) not null default 1540.00,
  tema_oscuro boolean not null default false,
  app_state_json jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. MESES (months) — Ingresos y fechas de cierre/vencimiento de tarjetas por mes
create table if not exists public.months (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  anio integer not null check (anio >= 2020 and anio <= 2100),
  mes integer not null check (mes >= 1 and mes <= 12),
  balance_inicial numeric(14,2) not null default 0.00,
  sueldo_mes numeric(14,2) not null default 2700000.00,
  horas_extras_real numeric(6,2) not null default 0.00,
  reintegro_real numeric(14,2) not null default 0.00,
  ingreso_extra_real numeric(14,2) not null default 0.00,
  cotizacion_usd numeric(12,2) not null default 1540.00,
  cierre_visa date,
  vencimiento_visa date,
  cierre_master date,
  vencimiento_master date,
  notas text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, anio, mes)
);

-- 3. MEDIOS DE PAGO (payment_methods)
create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  codigo text not null,
  nombre text not null,
  es_tarjeta boolean not null default true,
  color text not null default '#ee8434',
  orden integer not null default 1,
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

-- 4. CATEGORÍAS (categories)
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  color text not null default '#ee8434',
  icono text not null default '📦',
  presupuesto_mensual numeric(14,2),
  created_at timestamptz not null default now()
);

-- 5. PLANTILLAS DE GASTOS FIJOS RECURRENTES (recurring)
create table if not exists public.recurring (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  descripcion text not null,
  monto_ars numeric(14,2) not null default 0.00,
  monto_usd numeric(12,2),
  payment_method_id uuid references public.payment_methods(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  ubicacion text not null default 'fijos' check (ubicacion in ('fijos', 'tarjeta_visa', 'tarjeta_master')),
  desde_anio integer not null default 2026,
  desde_mes integer not null default 1,
  hasta_anio integer,
  hasta_mes integer,
  activo boolean not null default true,
  client_sync_id text unique,
  created_at timestamptz not null default now()
);

-- 6. DEUDAS EXTERNAS Y PRÉSTAMOS (debts)
create table if not exists public.debts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nombre text not null,
  saldo_total numeric(14,2) not null default 0.00,
  cuota_mensual numeric(14,2) not null default 0.00,
  tipo text not null check (tipo in ('externa', 'prestamo')),
  activo boolean not null default true,
  client_sync_id text unique,
  created_at timestamptz not null default now()
);

-- 7. MOVIMIENTOS Y CONSUMOS (transactions)
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  month_id uuid references public.months(id) on delete cascade,
  anio integer not null,
  mes integer not null,
  fecha date not null default current_date,
  descripcion text not null,
  monto_ars numeric(14,2) not null default 0.00,
  monto_usd numeric(12,2),
  cotizacion numeric(12,2),
  payment_method_id uuid references public.payment_methods(id) on delete set null,
  medio_codigo text not null default 'visa',
  category_id uuid references public.categories(id) on delete set null,
  categoria_nombre text not null default 'General',
  tipo text not null default 'consumo' check (tipo in ('consumo', 'fijo', 'deuda')),
  cuota_actual integer,
  cuota_total integer,
  grupo_cuota_id uuid,
  recurrente_id uuid references public.recurring(id) on delete set null,
  client_sync_id text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_months_user_ym on public.months(user_id, anio, mes);
create index if not exists idx_tx_user_ym on public.transactions(user_id, anio, mes);
create index if not exists idx_tx_grupo_cuota on public.transactions(grupo_cuota_id);
create index if not exists idx_recurring_user on public.recurring(user_id, activo);
create index if not exists idx_debts_user on public.debts(user_id, activo);

alter table public.profiles enable row level security;
alter table public.months enable row level security;
alter table public.payment_methods enable row level security;
alter table public.categories enable row level security;
alter table public.recurring enable row level security;
alter table public.debts enable row level security;
alter table public.transactions enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = user_id);
create policy "profiles_insert_own" on public.profiles for insert with check (auth.uid() = user_id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "profiles_delete_own" on public.profiles for delete using (auth.uid() = user_id);

create policy "months_select_own" on public.months for select using (auth.uid() = user_id);
create policy "months_insert_own" on public.months for insert with check (auth.uid() = user_id);
create policy "months_update_own" on public.months for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "months_delete_own" on public.months for delete using (auth.uid() = user_id);

create policy "payment_methods_select_own" on public.payment_methods for select using (auth.uid() = user_id);
create policy "payment_methods_insert_own" on public.payment_methods for insert with check (auth.uid() = user_id);
create policy "payment_methods_update_own" on public.payment_methods for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "payment_methods_delete_own" on public.payment_methods for delete using (auth.uid() = user_id);

create policy "categories_select_own" on public.categories for select using (auth.uid() = user_id);
create policy "categories_insert_own" on public.categories for insert with check (auth.uid() = user_id);
create policy "categories_update_own" on public.categories for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "categories_delete_own" on public.categories for delete using (auth.uid() = user_id);

create policy "recurring_select_own" on public.recurring for select using (auth.uid() = user_id);
create policy "recurring_insert_own" on public.recurring for insert with check (auth.uid() = user_id);
create policy "recurring_update_own" on public.recurring for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "recurring_delete_own" on public.recurring for delete using (auth.uid() = user_id);

create policy "debts_select_own" on public.debts for select using (auth.uid() = user_id);
create policy "debts_insert_own" on public.debts for insert with check (auth.uid() = user_id);
create policy "debts_update_own" on public.debts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "debts_delete_own" on public.debts for delete using (auth.uid() = user_id);

create policy "transactions_select_own" on public.transactions for select using (auth.uid() = user_id);
create policy "transactions_insert_own" on public.transactions for insert with check (auth.uid() = user_id);
create policy "transactions_update_own" on public.transactions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "transactions_delete_own" on public.transactions for delete using (auth.uid() = user_id);
