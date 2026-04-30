-- SOLUTION FINALE: Supprimer tout et recréer proprement

-- 1. Supprimer TOUT ce qui est lié à cet email (très agressif)
DELETE FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
DELETE FROM public.user_profiles WHERE id IN (SELECT id FROM auth.users WHERE email = 'belaggounamina2@gmail.com');
DELETE FROM auth.users WHERE email = 'belaggounamina2@gmail.com';

-- 2. Vérifier qu'il n'y a plus rien
SELECT 'Users restants:' as check_type, COUNT(*) as count FROM auth.users WHERE email = 'belaggounamina2@gmail.com'
UNION ALL
SELECT 'Profiles restants:', COUNT(*) FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';

-- 3. Créer l'utilisateur avec le mot de passe: 123456
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    last_sign_in_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000'::uuid,
    'belaggounamina2@gmail.com',
    crypt('123456', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin"}',
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
)
RETURNING id, email;

-- 4. Créer le profil admin
INSERT INTO public.user_profiles (id, email, role, full_name, created_at)
SELECT id, email, 'admin', 'Admin', NOW()
FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com';

-- 5. Vérification finale
SELECT '--- USER ---' as info, id::text, email, 'authenticated' as role FROM auth.users WHERE email = 'belaggounamina2@gmail.com'
UNION ALL
SELECT '--- PROFILE ---', id::text, email, role FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
