# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter e-commerce app ("Myazz", package name `myazz`, Android app id `com.myazz.app`) for a smart-watch/tech store, backed entirely by Supabase (PostgreSQL + Auth + Storage + RLS). State management is Provider. UI is dark-theme-only ("dark luxe") with some user-facing strings in French.

## Commands

```bash
flutter pub get                      # install dependencies
flutter run                          # run on connected device/emulator
flutter run -d chrome                # run web
flutter analyze                      # lint (flutter_lints ruleset)
flutter test                         # run tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk                    # Android release build
```

There is effectively no real test suite — only the default `test/widget_test.dart`.

## Environment / Supabase Setup

- Credentials come from `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), loaded via `flutter_dotenv`. `.env` is git-ignored but **bundled as a Flutter asset** (declared in `pubspec.yaml`), so it must exist for builds. Copy from `.env.example`.
- `lib/main.dart` contains hardcoded fallback Supabase credentials used when `.env` fails to load.
- `lib/services/api_service.dart` has a `_useMockData` flag and falls back to mock products in debug mode when Supabase calls fail.
- The `*.sql` files in the repo root are ad-hoc migrations/fixes meant to be run manually in the Supabase SQL editor; `supabase_schema.sql` is the base schema. Tables: `user_profiles` (roles: customer/admin), `products`, `orders`, `order_items`, `categories`. RLS is enabled — schema changes usually need a matching RLS policy SQL file.

## Architecture

Feature-first layout under `lib/features/`, but clean architecture is applied **inconsistently — follow the pattern of the feature you're touching**:

- `features/products/` is the only feature with full clean architecture: `domain/` (entities, repository interfaces, usecases returning `Either<Failure, T>` via dartz), `data/` (models, `ProductRepositoryImpl`), `presentation/` (screens + `ProductsProvider`).
- All other features (`auth`, `cart`, `favorites`, `orders`, `admin`, `profile`, `support`, `onboarding`) are presentation-only: screens that talk to Supabase directly or through providers.
- Cross-feature providers live in `lib/providers/` (`AuthProvider`, `CartProvider`, `FavoritesProvider`) and call `Supabase.instance.client` directly. All providers are registered in the `MultiProvider` in `main.dart`.
- `lib/services/api_service.dart` is a static-method Supabase wrapper (products/orders) that applies rate limiting and logging.

### Key cross-cutting pieces

- **Routing**: all named routes are declared in `main.dart`. `main.dart` also owns deep-link handling (`app_links`): `myazz://product/{id}`, OAuth `login-callback`, and password-reset links. An `onAuthStateChange` listener in `main.dart` navigates after OAuth sign-in (admin → `/admin`, else `/home`) and on password recovery.
- **Roles**: `AuthProvider.isAdmin` (from `user_profiles.role`) gates the admin dashboard routes.
- **Security utilities** (`lib/core/security/`): `InputSanitizer`, `InputValidator`, `RateLimiters` — user input and API calls are expected to go through these (see `SECURITY_IMPLEMENTATION.md` for the conventions).
- **Responsive sizing**: UI code uses `ResponsiveUtils.sw/sh/sf(context, n)` (scale from a 375px baseline) instead of raw pixel values — keep this convention in new widgets.
- **Theme**: `AppTheme.darkTheme` in `lib/theme/app_theme.dart` is the single theme.
- **Logging**: use `AppLogger` (`lib/core/utils/logger.dart`) with a `tag`, not raw `print`.

### Platform conditionals

Social login (Google/Facebook) buttons are hidden on iOS (`Platform.isIOS` / `kIsWeb` checks in login/register screens) — preserve this when touching auth UI. OAuth provider setup is documented in `OAUTH_SETUP.md`.
