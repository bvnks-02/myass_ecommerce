# MYAZZ Flutter App — AI Review Package

Generated: 2026-09-30 · branch `master` @ `11465da` (all work committed & pushed)
This zip contains the app's `lib/` source, `pubspec.yaml`, `AGENTS.md` (project conventions) and this document.
A matching release build exists at `build/app/outputs/flutter-apk/app-release.apk` (65.0 MB).

## What this app is

Flutter e-commerce app **Myazz** (package `myazz`), dark→light themed, Provider state,
feature-first layout under `lib/features/`. Backend = Supabase only.

**Supabase project: `myazz` / `icxcsjcmpipbtwzydzks`** (eu-central-1) — shared 1:1 with the
Next.js website at `~/myazz-ecomerce/web` (deployed myazz.store). Credentials come from
`.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) loaded in `lib/main.dart`. The old retired
project `pvxmqjdhmwpcoaqatzjb` is dead; `.env` now points at the website's project.

## Recent work (what a reviewer should look at)

### 1. Shared Supabase project sync (committed, pushed)
- `.env` repointed from the retired project to `icxcsjcmpipbtwzydzks`.
- Companion schema applied on the DB (lives in the web repo:
  `~/myazz-ecomerce/sql/app_companion_schema.sql`):
  - `user_profiles` = **view over the website's `profiles` table** (security_invoker),
    with app columns (email, role, avatar_url, height/weight, address fields) synced
    via INSTEAD OF triggers; role changes are admin-only.
  - products compat columns (`image`, `category`, `is_featured`, `is_available`,
    `sizes`, `colors`, `features`) kept two-ways in sync with the website's
    `image_url`/`featured`/`active` via trigger + auto-slug.
  - Checkout RPC `create_order_with_items` (atomic, server-priced,
    stock-decrementing, writes `full_name`/`phone`, wilaya `'Non spécifiée'`,
    lowercase order_status enum, idempotency key).
  - `messages` support-chat table + realtime + `mark_messages_read` RPC.
  - User order-cancel policy (pending→cancelled), `product-images`/`avatars` buckets.
- App compat fixes for the web schema: order screens read `price` (fallback
  `price_at_time`) and `image_url` (fallback `image`) — see
  `lib/features/orders/presentation/screens/user_orders_screen.dart`,
  `lib/features/admin/presentation/screens/admin_orders_screen.dart`.

### 2. Product picture fixed (DB + Storage, 2026-09-30)
- "Myazz One S" (id 2, 36 000 DA) had a website-relative path
  (`img/WhatsApp_Image_2026-07-01…png`) — unusable by the app.
- Uploaded the file to Storage → `product-images/products/myazz-one-s.png`
  and set `products.image_url`/`image`/`images` to the public URL:
  `https://icxcsjcmpipbtwzydzks.supabase.co/storage/v1/object/public/product-images/products/myazz-one-s.png`
  (works for both app and website; URL returns HTTP 200 image/png).

### 3. UI improvement pass (commit `ee82f46`)
- New widgets: `lib/core/widgets/price_text.dart` (website price typography:
  bold fg numerals + muted DA unit), `lib/core/widgets/press_scale.dart`
  (press feedback for cards/CTAs/steppers).
- Home: featured hero banner for the single catalog product, real French
  category fallbacks (was stale English), "Bientôt disponible" empty state,
  image contain-fit on ivory tiles, tightened grid rhythm.
- Product details: bordered `surface2` image tile so the transparent PNG
  reads intentionally; page dots hidden for single image; empty-image
  fallback + watch-icon error state.
- Cart/orders/dialogs: dark-pill actions with semantic success/danger,
  frosted checkout sheet, order total via PriceText (`36.000 DA`).
- `snackBarTheme`: floating rounded pill; 20px card radius rhythm; success
  SnackBars in accent gold.

### 4. Nav rework per annotation brief (commit `cec43d0`)
Bottom nav (left→right): watch-logo (`assets/icons/watch.png` → SmartWatch) ·
brand logo (`assets/images/logo.jpeg` → new BrandScreen at `/brand`) ·
raised gold center button (`Icons.sports` → Store, default landing index 2) ·
messages (`Icons.forum`, unread badge kept) · profile (unchanged).
Top bar: storefront icon replaces the heart (favorites detached — route intact,
reachable from Profile). Orders detached from nav — reachable via Profile →
Mes commandes. Placeholders: BrandScreen copy (« Notre histoire, bientôt. »)
and logo.jpeg rendered in ivory circle tiles (check on device).

### 5. myazz-ui skill pass — Luminous Glass & Gold (commit `11465da`)
Design system mounted from `myazz-ui/` (SKILL.md + `lib/theme/myazz_tokens.dart`):
- Pearl background `#F4F3F1→#FFFFFF` painted once at app root (transparent
  scaffolds); glass fills white .62/.82, hairline white borders, blur 24 cards /
  32 nav+sheets, radius 28, two-tier shadows.
- Champagne-gold gradient accent (4 stops `#F7E3A1→#8F6A1F`) replacing the
  single bronze accent; `GoldShader` for hero/details prices; `GoldCta`
  (gold ring + navy fill + 6s sheen) on add-to-cart and Place Order.
- Bottom nav: glass-strong bar with sliding gold pill active state; asset tabs
  get gold ring+glow when active; raised Sport button uses goldGradient.
- Effects per skill budget: staggered fade-up on home cards (one-shot, honors
  `MediaQuery.disableAnimations`), ONE sheen per screen max, ≤3 blur layers
  per screen.
- AppTheme remains the single API entry, delegating to `M` (myazz_tokens.dart);
  `lib/theme/gold_cta.dart` holds the shared CTA implementations.
- Fonts stay Inter (no google_fonts dep); no Arabic copy injected (app is LTR
  FR/EN) — the skill's RTL/bilingual checklist is parked until Arabic screens
  exist.

### 6. Earlier commits in this series
- `ee82f46` UI improvement pass (PriceText, PressScale, hero, empty states)
- `d23e2fc` light theme matching website palette + glassmorphism system
- `105d829` add-to-cart fly animation, home quick-add, screen polish
- `d4c5919` shared-schema field fallbacks for orders screens
- `438b42e` docs: shared Supabase project sync instructions

## Verification status
- `flutter analyze --no-pub`: **0 errors**, 16 issues (2 pre-existing warnings in
  `admin_orders_screen.dart` + infos). No new lints introduced.
- No new pub dependencies (glass uses `dart:ui` only). Inter font kept.
- Release APK rebuilt after the myazz-ui pass: `build/app/outputs/flutter-apk/app-release.apk` (65.0 MB).

## Known follow-ups (not in this zip's scope)
1. Some screens outside the scoped set (admin, auth, chat, smartwatch, profile,
   favorites, support) still carry dark-era hardcoded colors and will need a light-theme
   sweep (`grep -rn "Colors.white\|0xFF2C2C2E\|0xFF151515" lib/features`).
2. Supabase Auth dashboard needs redirect URL `com.example.myazz://login-callback`
   (and `reset_password`) added on the `myazz` project for OAuth/password flows on device.
3. Orders enum on the shared project is lowercase (`pending`, `cancelled`) — screens
   compare with `toLowerCase()`, but admin status-setting buttons send Title-case
   (`'Pending'`, `'Shipped'`…) in `admin_orders_screen.dart` and would fail against the
   enum; needs aligning to lowercase before admin order-status updates are used.
4. The old July `code.zip` snapshot was replaced by this package (refreshed after
   every work batch).

## Conventions (see AGENTS.md in the zip)
- Logging via `AppLogger` (tag), not print. Inputs through `InputSanitizer`/`RateLimiters`.
- Sizing via `ResponsiveUtils.sw/sh/sf(context, n)` (375px baseline).
- UI copy is mixed French/English. Prices integer DA via `CurrencyService`.
- Admin checks use `public.is_admin()`; never inline EXISTS over profiles (RLS recursion).
