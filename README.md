# MangoAR — PWA de Gastos Mensuales (Supabase + Vercel)

Aplicación web instalable (PWA) diseñada mobile-first para llevar el control mensual de ingresos, gastos en débito, ciclos de tarjetas de crédito (con fecha de cierre y fecha de vencimiento), cuotas automáticas, gastos fijos y deudas.

## Pasos para desplegar
1. En **Supabase** → **SQL Editor**, pegá y ejecutá `supabase_migrations.sql`.
2. Subí esta carpeta a **Vercel** (sin build step, 100% estático).
3. En la pestaña **Perfil** → **Sincronización Nube**, pegá tu `Project URL` y tu `Publishable / Anon Key`.
