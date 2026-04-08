-- Migration 005: maintenance_templates (read-only) and maintenance_records

-- ── maintenance_templates ──────────────────────────────────────────────────
-- Seeded from community/FIPE data. Read-only for regular users.
CREATE TABLE maintenance_templates (
  id              uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  make            text,           -- null = applies to all makes
  model           text,           -- null = applies to all models
  title           text    NOT NULL,
  interval_months integer,
  interval_km     integer,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- RLS: all authenticated users can read; no insert/update/delete via client
ALTER TABLE maintenance_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "maintenance_templates_select_all"
  ON maintenance_templates FOR SELECT
  USING (auth.role() = 'authenticated');

-- ── maintenance_records ────────────────────────────────────────────────────
CREATE TABLE maintenance_records (
  id             uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id     uuid           NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  title          text           NOT NULL,
  description    text,
  performed_at   date           NOT NULL,
  next_due_at    date,
  next_due_km    integer        CHECK (next_due_km IS NULL OR next_due_km >= 0),
  cost_brl       numeric(10, 2) CHECK (cost_brl IS NULL OR cost_brl >= 0),
  workshop_name  text,
  invoice_id     uuid,          -- FK added in migration 006 after invoices table exists
  created_at     timestamptz    NOT NULL DEFAULT now(),
  updated_at     timestamptz    NOT NULL DEFAULT now()
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "maintenance_records_select_own"
  ON maintenance_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = maintenance_records.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "maintenance_records_insert_own"
  ON maintenance_records FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = maintenance_records.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "maintenance_records_update_own"
  ON maintenance_records FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = maintenance_records.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "maintenance_records_delete_own"
  ON maintenance_records FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = maintenance_records.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

-- ── updated_at ─────────────────────────────────────────────────────────────
CREATE TRIGGER maintenance_records_updated_at
  BEFORE UPDATE ON maintenance_records
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
