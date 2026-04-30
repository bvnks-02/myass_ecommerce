-- Recréer complètement l'utilisateur admin avec un mot de passe sûr
-- Supprime l'ancien et crée un nouveau

-- 1. Supprimer l'ancien profil et utilisateur (tous les profils avec cet email)
DELETE FROM public.orders WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'belaggounamina2@gmail.com');
DELETE FROM public.user_profiles WHERE id IN (SELECT id FROM auth.users WHERE email = 'belaggounamina2@gmail.com');
DELETE FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
DELETE FROM auth.users WHERE email = 'belaggounamina2@gmail.com';

-- 2. Créer un nouvel utilisateur avec mot de passe: Admin123!
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'belaggounamina2@gmail.com',
    crypt('Admin123!', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin User"}',
    NOW(),
    NOW()
)
RETURNING id;

-- 3. Créer ou mettre à jour le profil admin
INSERT INTO public.user_profiles (id, email, role, full_name)
SELECT 
    id,
    email,
    'admin',
    'Admin User'
FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com'
ON CONFLICT (id) 
DO UPDATE SET 
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

-- 4. Vérification
SELECT 'User created:' as info, id, email, role FROM auth.users WHERE email = 'belaggounamina2@gmail.com';
SELECT 'Profile created:' as info, id, email, role FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
