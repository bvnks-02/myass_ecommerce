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
