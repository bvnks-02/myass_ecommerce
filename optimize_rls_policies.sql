-- Performance: collapse duplicate permissive RLS policies into single OR-based
-- policies so each row is evaluated once (clears the Supabase linter's
-- multiple_permissive_policies warnings). Run in the Supabase SQL Editor.

-- user_profiles: "own OR admin" read as one policy.
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "View own profile or admin views all" ON public.user_profiles
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = id OR public.is_admin());

-- orders: consolidate SELECT and UPDATE.
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;
CREATE POLICY "View own orders or admin views all" ON public.orders
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own order status" ON public.orders;
DROP POLICY IF EXISTS "Admins can update all orders" ON public.orders;
CREATE POLICY "Update own order or admin updates all" ON public.orders
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id OR public.is_admin())
  WITH CHECK ((select auth.uid()) = user_id OR public.is_admin());

-- order_items: consolidate SELECT.
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Admins can view all order items" ON public.order_items;
CREATE POLICY "View own order items or admin views all" ON public.order_items
  FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.orders
      WHERE id = order_items.order_id AND user_id = (select auth.uid())
    )
  );

-- products: public SELECT is the only read policy; admin writes split off FOR ALL.
DROP POLICY IF EXISTS "Products are modifiable by admins" ON public.products;
CREATE POLICY "Products insertable by admins" ON public.products
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "Products updatable by admins" ON public.products
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "Products deletable by admins" ON public.products
  FOR DELETE TO authenticated USING (public.is_admin());

-- categories: same treatment as products.
DROP POLICY IF EXISTS "Categories are modifiable by admins" ON public.categories;
CREATE POLICY "Categories insertable by admins" ON public.categories
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "Categories updatable by admins" ON public.categories
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "Categories deletable by admins" ON public.categories
  FOR DELETE TO authenticated USING (public.is_admin());
