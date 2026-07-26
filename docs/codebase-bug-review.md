# Codebase bug review — Myazz

**Date:** 2026-07-21  
**Scope:** Flutter app (`lib/`), root Supabase `*.sql`, auth/OAuth wiring  
**Method:** 4 parallel domain audits → Oracle severity triage → this report  
**Assumption:** Live DB has applied historical RLS fix scripts (`fix_admin_rls.sql`, `optimize_rls_policies.sql`, etc.). If not, data-plane severity is higher.

---

## Executive summary

Checkout can leave **orphan orders** (order row without items) while the user sees failure. Several auth UX bugs mislead users (false success, unconfirmed email treated as signed-in). Password reset is **broken on Android**. Admin UI has a **hardcoded email backdoor**. Schema is fragmented across manual SQL scripts; a fresh project is incomplete (chat, categories, profile columns, `product-images` bucket).

Client-side `isAdmin` and rate limits are **not** security boundaries — RLS is. Admin UI exposure without route guards is defense-in-depth only.

---

## Severity legend

| Level | Meaning |
|-------|---------|
| **P0** | Common-path data integrity / money / clear breach of intended privilege |
| **P1** | Broken feature, merchant data loss, or real security weakness |
| **P2** | Edge bug, hygiene, or product decision |
| **P3** | Smell / dead code / chore |

---

## Confirmed findings (post-Oracle)

### P0

| ID | Finding | Evidence | Impact |
|----|---------|----------|--------|
| **C2+C3+C10+C11** | Non-atomic order create; client total/`price_at_time`; errors → `false` only | `lib/services/api_service.dart` `createOrder` (~120–175); cart builds total client-side | Orphan Pending orders; silent failure; client can underpay if only client total is trusted |

### P1 — app code

| ID | Finding | Evidence | Impact |
|----|---------|----------|--------|
| **A5** | Android missing `reset_password` intent-filter | `AndroidManifest.xml` vs `AuthProvider` redirect `com.example.myazz://reset_password/` | Password reset dead on Android (primary mobile) |
| **A2** | Hardcoded admin email backdoor | `lib/providers/auth_provider.dart` `isAdmin` | Named Gmail always gets admin UI/nav (RLS still gates data writes) |
| **A3** | Unconfirmed email still sets `_user` | `signIn` sets user before session-null check; login navigates on `isAuthenticated` | User enters app without session |
| **A4** | Auth screens show success despite provider errors | forgot/reset/register screens ignore `hasError` after await | False confirmation on failed reset/register/password update |
| **U1** | Deep link unknown product → first catalog item | `lib/main.dart` `firstWhere(..., orElse: () => products.first)` | Wrong product opened from share links |
| **C1+C5** | Debug mock product fallback; brittle `fromJson` parse | `api_service.dart` `kDebugMode` catch; `product_model.dart` `int.parse`/`double.parse` | Dev masks real DB failures; one bad row kills entire grid |
| **C9** | Admin edit without new images drops gallery | `admin_product_list_screen.dart` `allImages = [product.image]` | Merchant gallery wiped on text-only edit |
| **A13** | Passwords run through destructive `sanitizeString` | login/register/reset call `InputSanitizer.sanitizeString` on password | Characters stripped; reset vs login can diverge |

### P1 — ops / SQL (not pure app bugs)

| ID | Finding | Evidence | Impact |
|----|---------|----------|--------|
| **S1+S2–S11+S8** | Fragmented manual SQL; missing bucket; harmful script order; broad user order UPDATE | Root `*.sql`; no `product-images` bucket SQL; `fix_order_items_rls.sql` drops INSERT; cancel RLS allows any column UPDATE | Fresh deploy broken; wrong apply order breaks checkout; users can rewrite order totals post-purchase |

### P2 (report only — not in remediation pass)

- **A1** — Hardcoded Supabase URL+anon fallback (anon is public; silent misconfig is the real issue) — fail loud instead  
- **A7/U10** — OAuth double navigation (main + login/register listeners)  
- **A9** — OAuth scheme `com.example.myazz` ≠ package `com.myazz.app`; no iOS URL types (coordinated ops — do not “fix” casually)  
- **A10/U3** — Admin routes lack client `isAdmin` guard (defense-in-depth; RLS assumed)  
- **C7/C8** — Cart/favorites in-memory only (product decision)  
- **C14** — Admin save does not invalidate `ProductsProvider` cache  
- **C15** — Admin orders N+1 queries  
- **U5–U7** — Chat unread/markRead quirks  
- **U8, U11, U12** — dispose / setState-after-dispose hygiene  
- **U14** — Tab switch recreates screens (no IndexedStack)  
- **U15** — `watch_detail_screen` hardcoded id 21 + wrong-product fallback  
- **PII logs** — order name/phone/address and emails via `debugPrint` (still can appear in release)

### Rejected / demoted

| Claim | Why rejected |
|-------|----------------|
| Anon key in binary as P0 | Supabase anon is public by design |
| Facebook App ID/token as secret leak | Public SDK identifiers |
| AuthProvider subscription “leak” | App-lifetime provider |
| Smartwatch mock-as-real as bug | Documented product mock |
| Currency app bug (DZD vs USD) | App convention: prices stored in DZD; seed data only looks USD |
| `getCheckoutData` key mismatch | Dead code; live cart path uses correct keys |
| Stale counter `widget_test` as P1 | Chore (P3) |
| Client rate limiter as security bug | UX throttle only |

---

## Remediation backlog (ordered)

Use this order in the fix pass:

1. **Atomic server-priced order RPC** + app `createOrder` rewrite (C2+C3+C10+C11)  
2. **Android password-reset intent-filter** + remove dead `reset_password` branch (A5/A6)  
3. **Remove admin email backdoor** (A2)  
4. **Unconfirmed email: clear `_user`** (A3)  
5. **Auth screens check `hasError` before success UI** (A4)  
6. **Deep link: never fallback to another product** (U1)  
7. **Remove debug mock fallback; harden `ProductModel.fromJson`** (C1+C5)  
8. **Admin edit preserve gallery images** (C9)  
9. **Stop sanitizing passwords** (A13)  
10. **Canonical idempotent SQL** (storage bucket, missing columns/tables, restore order_items INSERT, restrict user order UPDATE) + docs note (S*)  
11. *(stretch)* Invalidate products cache after admin save (C14)  
12. *(stretch)* Guard `watch_detail` wrong-product fallback (U15)

### Hard constraints

- Do **not** change OAuth scheme without updating Supabase + native manifests together.  
- Historical SQL scripts: prefer one new canonical script; do not delete apply history blindly.  
- Item 1 is the only intentional DB contract change for checkout.

---

## Remediation status (2026-07-21)

| # | Item | Status |
|---|------|--------|
| 1 | Atomic order RPC + app `createOrder` | **Done** — `create_order_with_items.sql` + `ApiService.createOrder` RPC |
| 2 | Android password-reset intent-filter | **Done** — `AndroidManifest.xml` |
| 3 | Remove admin email backdoor | **Done** — `AuthProvider.isAdmin` |
| 4 | Unconfirmed email clears `_user` | **Done** — `signIn` |
| 5 | Auth screens check `hasError` | **Done** — forgot/reset/register/login |
| 6 | Deep link no wrong product | **Done** — `main.dart` |
| 7 | Mock fallback removed + fromJson harden | **Done** — `api_service` / `product_model` |
| 8 | Admin edit preserve gallery | **Done** — `admin_product_list_screen` |
| 9 | Stop sanitizing passwords | **Done** — login/register/reset |
| 10 | Canonical schema SQL | **Done** — `ensure_canonical_schema.sql` |

**Ops required:** run in Supabase SQL Editor, in order:
1. `ensure_canonical_schema.sql`
2. `create_order_with_items.sql`

Checkout will fail until the RPC exists on the project.

### Follow-up pass (P2 / stretch)

| Item | Status |
|------|--------|
| U15 watch_detail wrong-product fallback | **Done** |
| C14 invalidate ProductsProvider after admin save/delete | **Done** |
| A10/U3 admin route `_AdminGate` | **Done** |
| A7/U10 OAuth nav race (screens no longer push) | **Done** |
| U8 onboarding PageController dispose | **Done** |
| U11/U12 mounted guards | **Done** |
| U5–U7 chat unread/markRead | **Done** |
| A1 louder .env fallback warning | **Done** (still falls back for dev) |
| PII: stop logging email on sign-in | **Done** |

## Validation notes

- No automated product test suite (`test/widget_test.dart` is stale counter).  
- `flutter analyze` on touched Dart files: no errors (1 unused import fixed).  
- Manual still needed: checkout after SQL apply; password-reset on Android; admin text-only product edit; unconfirmed-email login.

---

## Related docs

- `AGENTS.md` — agent working notes  
- `OAUTH_SETUP.md` — OAuth scheme quirks  
- `SECURITY_IMPLEMENTATION.md` — sanitizer/rate-limit conventions  
- Deepwork state (local): `.slim/deepwork/codebase-bug-review.md`
