-- Security hardening for SECURITY DEFINER helper functions.
-- Run in the Supabase SQL Editor after supabase_schema.sql.
--
-- handle_new_user() is only ever invoked by the on_auth_user_created trigger,
-- so it never needs to be callable directly (this also closes the
-- /rest/v1/rpc/handle_new_user endpoint flagged by the Supabase linter).
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- is_admin() is referenced by RLS policies, which are evaluated as the querying
-- role, so the authenticated role must keep EXECUTE. anon never needs it.
-- (The remaining "authenticated can execute is_admin" linter warning is expected
-- and safe: the function only reveals the caller's own admin status.)
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
