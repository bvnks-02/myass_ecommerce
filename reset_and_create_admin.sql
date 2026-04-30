-- ATTENTION: Ce script supprime TOUS les utilisateurs et crée un nouvel admin
-- À exécuter dans Supabase SQL Editor

-- Étape 1: Supprimer toutes les commandes (dépend des users)
DELETE FROM public.orders;

-- Étape 2: Supprimer tous les profils utilisateurs
DELETE FROM public.user_profiles;

-- Étape 3: Supprimer tous les utilisateurs de auth.users
-- Note: Nécessite des privilèges spéciaux
DELETE FROM auth.users;

-- Étape 4: Créer un nouvel utilisateur admin
-- Remplacez par vos informations
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    role
) VALUES (
    gen_random_uuid(),  -- Génère un nouvel UUID
    'belaggounamina2@gmail.com',  -- EMAIL ADMIN
    crypt('admin123456', gen_salt('bf')),  -- MOT DE PASSE: changez-le!
    NOW(),  -- Email confirmé automatiquement
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin"}',
    NOW(),
    NOW(),
    'authenticated'
)
RETURNING id;

-- Étape 5: Créer ou mettre à jour le profil admin
-- Utilise UPSERT (INSERT ON CONFLICT) pour mettre à jour si existe déjà
INSERT INTO public.user_profiles (id, email, role, full_name)
SELECT 
    id,
    email,
    'admin',
    'Admin'
FROM auth.users 
WHERE email = 'belaggounamina2@gmail.com'
ON CONFLICT (id) 
DO UPDATE SET 
    role = EXCLUDED.role,
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

-- Vérification
SELECT * FROM public.user_profiles WHERE email = 'belaggounamina2@gmail.com';
SELECT * FROM auth.users WHERE email = 'belaggounamina2@gmail.com';
