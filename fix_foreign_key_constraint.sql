-- Solution pour permettre la suppression des produits dans Supabase
-- Exécute ce script dans l'éditeur SQL Supabase

-- Étape 1: Supprimer la contrainte de clé étrangère existante
ALTER TABLE public.order_items 
DROP CONSTRAINT IF EXISTS order_items_product_id_fkey;

-- Étape 2: Ajouter une nouvelle contrainte avec ON DELETE CASCADE
ALTER TABLE public.order_items 
ADD CONSTRAINT order_items_product_id_fkey 
FOREIGN KEY (product_id) REFERENCES public.products(id) 
ON DELETE CASCADE;

-- Étape 3: Vérifier que la contrainte a été correctement ajoutée
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name
WHERE tc.table_name = 'order_items' 
    AND tc.constraint_name = 'order_items_product_id_fkey';

-- Étape 4: Test de suppression (optionnel - à décommenter pour tester)
-- DELETE FROM public.products WHERE id = 1;
