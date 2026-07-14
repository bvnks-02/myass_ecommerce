# OAuth Setup Guide for Google and Facebook Login

## Current configuration status (verified — Lot 3)

Supabase project in use: **`ifosyvmoynhglyxcitvw`** (`https://ifosyvmoynhglyxcitvw.supabase.co`).

What is already correct in the codebase:

- **Android** registers the OAuth callback scheme in `AndroidManifest.xml`:
  `com.example.myazz://login-callback/` — and `AuthProvider.signInWithGoogle`
  redirects to that exact URI, so the Android round-trip is wired correctly.
- The cold-start / warm deep-link handler in `main.dart` forwards any link
  containing `login-callback`, `access_token=`, or `code=` to
  `Supabase.auth.getSessionFromUrl`, completing sign-in.
- **First Google sign-in now creates a `user_profiles` row reliably.** The DB
  trigger `on_auth_user_created` handles this, and `AuthProvider.refreshRole`
  has a defensive fallback (`_ensureProfileExists`) that upserts the row if the
  trigger ever fails to run. `refreshRole` uses `maybeSingle()` so a missing
  profile no longer throws.

What still requires **manual dashboard configuration** (cannot be done from code):

1. **Enable the Google provider** in Supabase → Authentication → Providers →
   Google, using a Client ID/Secret from a Google Cloud OAuth app (see below).
2. **Add the redirect URLs** in Supabase → Authentication → URL Configuration →
   Redirect URLs:
   - `com.example.myazz://login-callback/`
   - `com.example.myazz://reset_password/`
3. In the Google Cloud OAuth app, register the same
   `com.example.myazz://login-callback/` redirect and the Android package
   `com.myazz.app` with the signing SHA-1.

> **Note on the URL scheme:** the custom scheme is `com.example.myazz` (a leftover
> from the original package id). It does not need to match the real app id
> (`com.myazz.app`) to work, and it is internally consistent between the Android
> manifest, `AuthProvider`, and the redirect URLs — so it is left as-is to avoid a
> risky multi-place rename. If you ever rename it, change it in all four places:
> `AndroidManifest.xml`, `AuthProvider` (Google/Facebook/reset redirects),
> Supabase Redirect URLs, and the Google/Facebook OAuth apps.

> **Note on iOS:** `ios/Runner/Info.plist` does **not** declare a
> `CFBundleURLTypes` entry, so custom-scheme deep links (including OAuth
> callbacks) do not route on iOS. This is acceptable today because the
> Google/Facebook buttons are hidden on iOS (`Platform.isIOS` checks in the
> login/register screens). If social login is ever enabled on iOS, add a
> `CFBundleURLTypes` block registering `com.example.myazz`.

## Problem
Google and Facebook login are not working because OAuth providers need to be configured in Supabase.

## Solution: Configure OAuth in Supabase

### 1. Enable Google OAuth in Supabase

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Providers**
3. Find **Google** and click to enable it
4. You'll need to configure a Google OAuth app:

#### Creating Google OAuth App:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Go to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Configure:
   - **Application type**: Android
   - **Package name**: `com.example.myazz`
   - **SHA-1 fingerprint**: Get from your debug keystore
     ```
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
6. Copy the **Client ID** and paste it in Supabase Google provider settings
7. Add this redirect URL to Google OAuth app:
   - `com.example.myazz://login-callback/`

### 2. Enable Facebook OAuth in Supabase

1. In Supabase dashboard, go to **Authentication** > **Providers**
2. Find **Facebook** and click to enable it
3. You'll need to configure a Facebook OAuth app:

#### Creating Facebook OAuth App:
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app (select **Consumer** type)
3. Add **Facebook Login** product
4. In App Settings, configure:
   - **Android Package Name**: `com.example.myazz`
   - **Key Hashes**: Get from your debug keystore
     ```
     keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
     ```
5. Copy the **App ID** and **App Secret** to Supabase Facebook provider settings
6. Add this redirect URL to Facebook OAuth app:
   - `com.example.myazz://login-callback/`

### 3. Configure Redirect URLs in Supabase

In your Supabase project:
1. Go to **Project Settings** > **API**
2. Scroll to **Redirect URLs**
3. Add these URLs:
   - `com.example.myazz://login-callback/`
   - `com.example.myazz://reset_password/`
4. Save the changes

### 4. Test the Configuration

After completing the above:
1. Run your app: `flutter run`
2. Try logging in with Google
3. Try logging in with Facebook

## Quick Fix for Testing (Temporary)

If you want to test email login while OAuth is being configured:
- Use the regular email/password login
- This should work immediately if Supabase is properly set up

## Common Issues

### Issue: "OAuth provider not enabled"
**Solution**: Enable the provider in Supabase Authentication > Providers

### Issue: "Redirect URL not configured"
**Solution**: Add the redirect URL in Supabase Project Settings > API > Redirect URLs

### Issue: "Invalid redirect URI"
**Solution**: Make sure the redirect URL matches exactly in:
- Supabase settings
- Google/Facebook OAuth app settings
- Your auth_provider.dart file

### Issue: SHA-1 fingerprint errors
**Solution**: Use the correct debug keystore path:
- Windows: `%USERPROFILE%\.android\debug.keystore`
- macOS/Linux: `~/.android/debug.keystore`

## Production Setup

For production builds:
1. Create a release keystore
2. Generate SHA-1 and SHA-256 fingerprints from the release keystore
3. Add these fingerprints to Google and Facebook OAuth apps
4. Update the package name in build.gradle.kts from `com.example.myazz` to your actual package name
5. Update all redirect URLs to use your actual package name

## Need Help?

Check the Supabase documentation:
- [Google OAuth](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Facebook OAuth](https://supabase.com/docs/guides/auth/social-login/auth-facebook)
