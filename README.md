# MangoAR — PWA de Gastos Personales Mensuales

Aplicación web progresiva (PWA) mobile-first en HTML + CSS + JavaScript vanilla (sin frameworks ni pasos de compilación), diseñada para reemplazar tu planilla mensual de Excel (`Gastos.xlsx`) con sincronización en **Supabase (Postgres + Auth Magic Link + RLS)** y soporte **Offline-first** con cola de sincronización.

## Archivos incluidos
- `index.html`: Aplicación completa de página única (SPA/PWA) comentada en español rioplatense.
- `supabase_migrations.sql`: Esquema SQL completo con las 7 tablas (`profiles`, `months`, `payment_methods`, `categories`, `recurring`, `debts`, `transactions`), índices y políticas de **Row Level Security (RLS)** por `user_id`.
- `manifest.json`, `sw.js`, `icon-192.svg`, `icon-512.svg`: Archivos de instalación PWA y Service Worker para funcionamiento offline.
- `vercel.json`: Configuración lista para desplegar en Vercel.

## Cómo desplegar en 3 minutos
1. **Supabase**: Creá un proyecto en Supabase, abrí el **SQL Editor**, pegá el contenido de `supabase_migrations.sql` y ejecutalo.
2. **Vercel**: Subí esta carpeta a un repositorio de GitHub o arrastrala a Vercel (`npx vercel --prod`).
3. **Conectar**: Abrí la app en el celu, tocá el ícono de **Nube / Config** arriba a la derecha, pegá tu `SUPABASE_URL` y `SUPABASE_ANON_KEY`, e ingresá con tu email (Magic Link).
