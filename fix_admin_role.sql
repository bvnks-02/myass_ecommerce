-- Vérifier et corriger le rôle admin
-- Vérifie d'abord les IDs
SELECT 
    au.id as auth_id, 
    au.email as auth_email,
    up.id as profile_id,
    up.email as profile_email,
    up.role
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE au.email = 'belaggounamina2@gmail.com';

-- Si les IDs ne correspondent pas (profile_id est NULL ou différent),
-- supprime l'ancien profil et crée un nouveau avec le bon ID
DELETE FROM public.user_profiles 
WHERE email = 'belaggounamina2@gmail.com';

-- Insère le profil avec le BON ID (celui de auth.users)
INSERT INTO public.user_profiles (id, email, role, full_name)
SELECT 
    id,
    email,
    'admin',
    'Admin'
FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com';

-- Vérifie que c'est bon
SELECT * FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
