-- Migration: Add name column to orders table
-- Run this in your Supabase SQL Editor

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS name TEXT;
