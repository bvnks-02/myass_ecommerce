-- Run this script in the Supabase SQL Editor to create a new admin user
-- Replace the email and password below with your desired admin credentials

-- Step 1: Create a new user in Supabase Auth
-- NOTE: You need to run this via Supabase Dashboard > Authentication > Users > Add User
-- Or use the SQL below (requires service role key)

-- For SQL approach, you need to:
-- 1. Go to Supabase Dashboard
-- 2. Authentication > Users > Add new user
-- 3. Enter email and password, then auto-confirm the email
-- 4. Copy the user ID (UUID) from the Users table

-- Step 2: After creating the user, update their role to admin
-- Replace 'new_admin@example.com' with the actual email

UPDATE public.user_profiles
SET role = 'admin'
WHERE email = 'new_admin@example.com';

-- Step 3: Verify the admin was created successfully
SELECT id, email, role, created_at
FROM public.user_profiles
WHERE role = 'admin';

-- Step 4: Check if user_profiles entry exists for your email
-- If this returns nothing, the user_profiles entry wasn't created automatically
SELECT id, email, role, full_name
FROM public.user_profiles
WHERE email = 'new_admin@example.com';

-- Step 5: If user_profiles entry doesn't exist, create it manually
-- Replace 'YOUR_USER_ID_HERE' with the UUID from auth.users table
-- Replace 'new_admin@example.com' with your email

-- INSERT INTO public.user_profiles (id, email, role, full_name)
-- VALUES ('YOUR_USER_ID_HERE', 'new_admin@example.com', 'admin', 'Admin User');
