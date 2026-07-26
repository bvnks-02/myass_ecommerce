# AGENTS.md

Flutter e-commerce app **Myazz** (`package: myazz`, Android id `com.myazz.app`). Backend is Supabase only (Auth + Postgres RLS + Storage + Realtime). State: Provider. Theme: dark-only (`AppTheme.darkTheme`). UI copy is mixed French/English — match nearby strings.

Also see: `CLAUDE.md`, `OAUTH_SETUP.md`, `SECURITY_IMPLEMENTATION.md`.

## Commands

```bash
flutter pub get
flutter run                 # device/emulator
flutter run -d chrome       # web
flutter analyze             # flutter_lints only (analysis_options.yaml)
flutter test                # effectively no real suite
flutter test test/widget_test.dart
flutter build apk
```

`test/widget_test.dart` is still the default counter smoke test and does **not** match the app — do not treat a green `flutter test` as product coverage.

No CI workflows in-repo.

## Env / Supabase

- Copy `.env.example` → `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- `.env` is gitignored **and** listed under `flutter: assets` in `pubspec.yaml` — the file must exist or asset bundling fails. `main.dart` still falls back to hardcoded Supabase credentials if load fails.
- Root `*.sql` files are **manual** Supabase SQL Editor scripts, not a migration runner. Base: `supabase_schema.sql`. Apply extras as needed (`create_messages_table.sql`, `add_profile_details_columns.sql`, RLS fixes, etc.).
- Core tables: `user_profiles` (roles `customer`|`admin`), `products`, `orders`, `order_items`, `categories`, `messages`. RLS on; schema/policy changes need matching SQL + policies.
- Storage buckets used in code: `product-images` (admin product images), `avatars` (profile photos). Chat needs Realtime on `messages` + RPC `mark_messages_read`.

## Architecture (follow the feature you touch)

Feature-first under `lib/features/`, but layers are **inconsistent**:

| Area | Pattern |
|------|---------|
| `features/products/` | Full clean arch: domain (entities, repo iface, usecases → `Either` via dartz) / data / presentation |
| `features/chat/` | `data/` + `domain/` + presentation provider |
| Most others (`auth`, `cart`, `favorites`, `orders`, `admin`, `profile`, `support`, `onboarding`, `smartwatch`) | Presentation-heavy; talk to Supabase via providers or screens |

- Cross-feature providers in `lib/providers/`: `AuthProvider`, `CartProvider`, `FavoritesProvider` — call `Supabase.instance.client` directly.
- Feature-local providers (registered in `main.dart` `MultiProvider`): `ProductsProvider`, `SupportProvider`, `ChatProvider`, `SmartWatchProvider`.
- `lib/services/api_service.dart`: static Supabase wrapper (products/orders/categories) with client-side rate limits + sanitization. `ProductRepositoryImpl` delegates here. `_useMockData` is off; **debug mode falls back to mock products** on fetch failure — easy to mistake for a real empty DB.
- `features/smartwatch/`: **mocked** pairing/BLE catalog, not a real device SDK.

### Wiring you will hit

- **Entry + routes**: all named routes and `MainScreen` bottom tabs live in `lib/main.dart`. New screens need a route (and often a tab) there.
- **Deep links** (`app_links` in `main.dart`): product share `myazz://product/{id}`; OAuth/password flows via custom scheme (below).
- **Auth roles**: `AuthProvider.isAdmin` from `user_profiles.role`; post-OAuth navigation admin → `/admin`, else `/home`.
- **Currency**: `CurrencyService` defaults to **DZD** (`DA`); prices treated as already in DZD.
- **Logging**: `AppLogger` (`lib/core/utils/logger.dart`) with a `tag` — not raw `print`.
- **UI sizing**: prefer `ResponsiveUtils.sw/sh/sf(context, n)` (375px baseline) over hard-coded pixels.
- **Security**: user-facing inputs and API paths should go through `InputSanitizer` / `InputValidator` / `RateLimiters` (`lib/core/security/`). Conventions in `SECURITY_IMPLEMENTATION.md`.

## Platform / OAuth gotchas

- Social login (Google/Facebook) visibility: `showSocialAuth` in `lib/core/utils/platform_utils.dart` — **hidden on iOS** (`kIsWeb` checked before `Platform.isIOS`). Preserve when editing auth UI.
- OAuth redirect scheme is still **`com.example.myazz`** (`login-callback`, `reset_password`) in `AuthProvider`, AndroidManifest, and Supabase config — **not** `com.myazz.app`. Documented in `OAUTH_SETUP.md`. Do not “fix” the scheme without updating Supabase + native manifests together.
- Product deep link scheme is separate: `myazz://product/...`.

## When changing the DB

1. Prefer a new root `*.sql` script (or update schema docs) over silent app-only assumptions.
2. Keep RLS policies aligned (many historical fix scripts exist — read before inventing new policies).
3. Admin elevation is SQL: `UPDATE user_profiles SET role = 'admin' WHERE email = '...'`.
4. Fresh / rebuild apply order after `supabase_schema.sql`: `ensure_canonical_schema.sql` then `create_order_with_items.sql`. Checkout uses RPC `create_order_with_items` (server-priced); do not reintroduce client-only order inserts.
5. Bug review findings: `docs/codebase-bug-review.md`.
