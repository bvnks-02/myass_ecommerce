-- Migration script to add soft delete functionality to products table
-- Run this script in the Supabase SQL Editor

-- Add is_active column to products table
ALTER TABLE public.products 
ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

-- Add deleted_at column to products table  
ALTER TABLE public.products 
ADD COLUMN deleted_at TIMESTAMPTZ;

-- Update existing products to have is_active = TRUE (they should already be active)
UPDATE public.products 
SET is_active = TRUE 
WHERE is_active IS NULL;

-- Create index for better performance on active products
CREATE INDEX idx_products_is_active ON public.products(is_active);

-- Create index for soft-deleted products
CREATE INDEX idx_products_deleted_at ON public.products(deleted_at);

-- Update the products policy to handle soft deletes
-- Drop existing policy first
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;

-- Create new policy that excludes soft-deleted products for regular users
CREATE POLICY "Active products are viewable by everyone" ON public.products
  FOR SELECT USING (is_active = TRUE OR is_active IS NULL);

-- Admin policy to see all products (including soft-deleted)
DROP POLICY IF EXISTS "Products are insertable/updatable/deletable by admins" ON public.products;

CREATE POLICY "Products are manageable by admins" ON public.products
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create a function to safely delete products (handles constraints)
CREATE OR REPLACE FUNCTION public.safe_delete_product(product_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    order_count INTEGER;
BEGIN
    -- Check if product is referenced in orders
    SELECT COUNT(*) INTO order_count
    FROM public.order_items 
    WHERE product_id = safe_delete_product.product_id;
    
    IF order_count > 0 THEN
        -- Soft delete if referenced
        UPDATE public.products 
        SET is_active = FALSE, deleted_at = NOW()
        WHERE id = product_id;
        RETURN TRUE;
    ELSE
        -- Hard delete if not referenced
        DELETE FROM public.products WHERE id = product_id;
        RETURN TRUE;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error deleting product: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.safe_delete_product TO authenticated;
