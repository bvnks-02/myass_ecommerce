-- Add policy to allow users to update their own orders (for cancelling)
-- This allows customers to change the status of their own orders

CREATE POLICY "Users can update own order status" ON public.orders
  FOR UPDATE USING (
    auth.uid() = user_id
  )
  WITH CHECK (
    auth.uid() = user_id
  );
