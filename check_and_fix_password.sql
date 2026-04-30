-- Vérifier l'utilisateur existant
SELECT id, email, created_at, email_confirmed_at 
FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com';

-- Mettre à jour le mot de passe avec un mot de passe simple sans caractères spéciaux
UPDATE auth.users 
SET encrypted_password = crypt('admin123', gen_salt('bf'))
WHERE email = 'belaggounamina2@gmail.com';

-- Vérifier que le profil est bien admin
UPDATE public.user_profiles 
SET role = 'admin'
WHERE email = 'belaggounamina2@gmail.com';

-- Vérification finale
SELECT au.id, au.email, up.role 
FROM auth.users au
JOIN public.user_profiles up ON au.id = up.id
WHERE au.email = 'belaggounamina2@gmail.com';
