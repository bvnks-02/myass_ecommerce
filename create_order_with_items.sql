-- Atomic order creation. Apply in Supabase SQL Editor.
-- App calls: rpc('create_order_with_items', { p_name, p_phone, p_address, p_items })
-- Requires order_items.color/size columns (see ensure_canonical_schema.sql).

CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_name text,
  p_phone text,
  p_address text,
  p_items jsonb
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_order_id bigint;
  v_total numeric(10,2) := 0;
  v_item jsonb;
  v_product_id bigint;
  v_qty int;
  v_price numeric(10,2);
  v_available boolean;
  v_color text;
  v_size text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'order must contain at least one item';
  END IF;

  IF p_name IS NULL OR length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'name is required';
  END IF;

  -- Validate items and compute server-side total
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::bigint;
    v_qty := COALESCE((v_item->>'quantity')::int, 0);

    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'invalid product_id';
    END IF;
    IF v_qty IS NULL OR v_qty < 1 THEN
      RAISE EXCEPTION 'invalid quantity for product %', v_product_id;
    END IF;

    SELECT p.price,
           COALESCE(p.is_available, true)
      INTO v_price, v_available
      FROM public.products p
     WHERE p.id = v_product_id
     FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'product % not found', v_product_id;
    END IF;

    IF v_available IS DISTINCT FROM true THEN
      RAISE EXCEPTION 'product % is unavailable', v_product_id;
    END IF;

    v_total := v_total + (v_price * v_qty);
  END LOOP;

  INSERT INTO public.orders (user_id, total_amount, name, phone, address, status)
  VALUES (
    v_uid,
    v_total,
    left(trim(p_name), 100),
    left(trim(COALESCE(p_phone, '')), 40),
    left(trim(COALESCE(p_address, '')), 500),
    'Pending'
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::bigint;
    v_qty := (v_item->>'quantity')::int;
    v_color := NULLIF(trim(v_item->>'color'), '');
    v_size := NULLIF(trim(v_item->>'size'), '');

    SELECT p.price INTO v_price
      FROM public.products p
     WHERE p.id = v_product_id;

    INSERT INTO public.order_items (order_id, product_id, quantity, price_at_time, color, size)
    VALUES (v_order_id, v_product_id, v_qty, v_price, v_color, v_size);
  END LOOP;

  RETURN v_order_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_order_with_items(text, text, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(text, text, text, jsonb) TO authenticated;
