-- Add is_available column to products table
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- Update existing products to be available by default
UPDATE public.products SET is_available = TRUE WHERE is_available IS NULL;
