-- Migration 006: invoices and invoice_items tables, RLS, and FK back to maintenance_records

-- ── invoices ──────────────────────────────────────────────────────────────
CREATE TABLE invoices (
  id           uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id   uuid           NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  photo_url    text           NOT NULL,  -- Supabase Storage path
  ai_parsed_at timestamptz,              -- null until Edge Function completes
  raw_text     text,                     -- full OCR output
  total_brl    numeric(10, 2),
  issued_at    date,
  created_at   timestamptz    NOT NULL DEFAULT now(),
  updated_at   timestamptz    NOT NULL DEFAULT now()
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoices_select_own"
  ON invoices FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = invoices.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoices_insert_own"
  ON invoices FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = invoices.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoices_update_own"
  ON invoices FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = invoices.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoices_delete_own"
  ON invoices FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = invoices.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

-- ── invoice_items ─────────────────────────────────────────────────────────
CREATE TABLE invoice_items (
  id          uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id  uuid           NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description text           NOT NULL,
  quantity    numeric        NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price  numeric(10, 2) NOT NULL CHECK (unit_price >= 0),
  item_type   text           NOT NULL CHECK (item_type IN ('part', 'labor', 'other')),
  created_at  timestamptz    NOT NULL DEFAULT now(),
  updated_at  timestamptz    NOT NULL DEFAULT now()
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoice_items_select_own"
  ON invoice_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM invoices i
        JOIN vehicles v ON v.id = i.vehicle_id
      WHERE i.id = invoice_items.invoice_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoice_items_insert_own"
  ON invoice_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM invoices i
        JOIN vehicles v ON v.id = i.vehicle_id
      WHERE i.id = invoice_items.invoice_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoice_items_update_own"
  ON invoice_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM invoices i
        JOIN vehicles v ON v.id = i.vehicle_id
      WHERE i.id = invoice_items.invoice_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "invoice_items_delete_own"
  ON invoice_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM invoices i
        JOIN vehicles v ON v.id = i.vehicle_id
      WHERE i.id = invoice_items.invoice_id
        AND v.owner_id = auth.uid()
    )
  );

-- ── updated_at ─────────────────────────────────────────────────────────────
CREATE TRIGGER invoices_updated_at
  BEFORE UPDATE ON invoices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER invoice_items_updated_at
  BEFORE UPDATE ON invoice_items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Add FK from maintenance_records to invoices (deferred from migration 005) ──
ALTER TABLE maintenance_records
  ADD CONSTRAINT maintenance_records_invoice_id_fkey
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL;
