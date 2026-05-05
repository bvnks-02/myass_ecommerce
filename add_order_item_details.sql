-- Add color and size columns to order_items table
-- Run this in Supabase SQL Editor

-- Add color column
ALTER TABLE public.order_items 
ADD COLUMN IF NOT EXISTS color TEXT;

-- Add size column  
ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS size TEXT;

-- Add selected_options JSONB for any additional options
ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT '{}';

COMMENT ON COLUMN public.order_items.color IS 'Selected watch color';
COMMENT ON COLUMN public.order_items.size IS 'Selected watch size (e.g., 41mm, 45mm)';
