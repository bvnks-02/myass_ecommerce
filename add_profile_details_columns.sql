-- Lot 2: profile dashboard fields for user_profiles + avatars storage bucket.
-- Run in the Supabase SQL Editor.
--
-- Design choice: extend user_profiles in-place rather than a separate addresses
-- table. The CDC requires a single shipping address + single billing address per
-- user; user_profiles is already a 1:1-with-auth.users owned row guarded by
-- auth.uid() RLS, so a dedicated table would add a join and duplicate RLS for no
-- modeling benefit. Revisit only if multiple saved addresses are ever needed.

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS height NUMERIC,
  ADD COLUMN IF NOT EXISTS weight NUMERIC,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS address_line1 TEXT,
  ADD COLUMN IF NOT EXISTS address_line2 TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS postal_code TEXT,
  ADD COLUMN IF NOT EXISTS billing_same_as_shipping BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS billing_address_line1 TEXT,
  ADD COLUMN IF NOT EXISTS billing_address_line2 TEXT,
  ADD COLUMN IF NOT EXISTS billing_city TEXT,
  ADD COLUMN IF NOT EXISTS billing_postal_code TEXT;

-- Defensive server-side bounds mirroring the client InputValidator ranges.
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_height_ck,
  DROP CONSTRAINT IF EXISTS user_profiles_weight_ck;
ALTER TABLE public.user_profiles
  ADD CONSTRAINT user_profiles_height_ck
    CHECK (height IS NULL OR (height >= 30 AND height <= 300)),
  ADD CONSTRAINT user_profiles_weight_ck
    CHECK (weight IS NULL OR (weight >= 20 AND weight <= 500));

-- The app upserts into user_profiles (saveProfileDetails, updateAvatar, and
-- the first-OAuth-sign-in fallback), which needs INSERT + UPDATE policies on
-- top of the SELECT-only policies in supabase_schema.sql. These match the
-- policies already live on the project; kept here so a rebuild from the repo's
-- SQL files reproduces them.
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- The UPDATE policy alone would let a user set role='admin' on their own row
-- (privilege escalation: is_admin() gates every admin RLS path). This trigger
-- blocks role changes unless the caller is already an admin. Dashboard /
-- service-role sessions have auth.uid() = NULL and stay exempt, so the owner
-- can still promote admins from the SQL editor.
CREATE OR REPLACE FUNCTION public.protect_user_profile_role()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role
     AND (select auth.uid()) IS NOT NULL
     AND NOT COALESCE(public.is_admin(), false) THEN
    RAISE EXCEPTION 'changing role requires admin privileges';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS protect_role ON public.user_profiles;
CREATE TRIGGER protect_role
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_user_profile_role();

-- Avatar storage: public-read bucket so avatar_url resolves without signing;
-- writes are locked to the owner's {uid}/ folder. Upsert needs INSERT+SELECT+UPDATE.
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly readable" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

-- Public URL access works via the public CDN path and does not consult this
-- SELECT policy, so scope SELECT to the owner's own folder (prevents clients
-- from listing every file in the bucket).
CREATE POLICY "Users can list own avatar folder"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );
