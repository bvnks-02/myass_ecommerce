-- Supprimer l'utilisateur et tout ce qui est lié

-- 1. D'abord supprimer les commandes liées
DELETE FROM public.orders 
WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'belaggounamina2@gmail.com');

-- 2. Supprimer le profil
DELETE FROM public.user_profiles 
WHERE email = 'belaggounamina2@gmail.com';

-- 3. Maintenant supprimer l'utilisateur
DELETE FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com';

-- 4. Vérifier
SELECT 'Reste dans auth.users:' as check_type, COUNT(*) as count FROM auth.users WHERE email = 'belaggounamina2@gmail.com'
UNION ALL
SELECT 'Reste dans user_profiles:', COUNT(*) FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
