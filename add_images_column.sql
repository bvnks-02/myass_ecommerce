-- Add images column to products table for multiple product images
ALTER TABLE products ADD COLUMN images JSONB DEFAULT NULL;

-- Add comment for documentation
COMMENT ON COLUMN products.images IS 'Array of additional product image URLs';

-- Refresh PostgREST schema cache (important!)
NOTIFY pgrst, 'reload schema';
