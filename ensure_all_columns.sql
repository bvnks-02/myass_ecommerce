-- Comprehensive migration to ensure all required columns exist
-- Run this in Supabase SQL Editor

-- Orders table columns
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS name TEXT;

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS phone TEXT;

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS address TEXT;

-- Order items table columns
ALTER TABLE public.order_items 
ADD COLUMN IF NOT EXISTS color TEXT;

ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS size TEXT;

ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT '{}';

-- Products table columns
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE;

-- Update existing products to be available by default
UPDATE public.products SET is_available = TRUE WHERE is_available IS NULL;

-- Add comments
COMMENT ON COLUMN public.orders.name IS 'Customer name for delivery';
COMMENT ON COLUMN public.orders.phone IS 'Customer phone number';
COMMENT ON COLUMN public.orders.address IS 'Delivery address';
COMMENT ON COLUMN public.order_items.color IS 'Selected watch color';
COMMENT ON COLUMN public.order_items.size IS 'Selected watch size (e.g., 41mm, 45mm)';
COMMENT ON COLUMN public.order_items.selected_options IS 'Additional selected options as JSON';
COMMENT ON COLUMN public.products.is_available IS 'Whether the product is available for purchase';
