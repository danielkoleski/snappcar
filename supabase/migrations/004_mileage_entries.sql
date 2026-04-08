-- Migration 004: mileage_entries table and RLS

CREATE TABLE mileage_entries (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id  uuid        NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  recorded_km integer     NOT NULL CHECK (recorded_km >= 0),
  recorded_at date        NOT NULL DEFAULT CURRENT_DATE,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
-- Access is granted if the user owns the vehicle this entry belongs to.
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mileage_entries_select_own"
  ON mileage_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = mileage_entries.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "mileage_entries_insert_own"
  ON mileage_entries FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = mileage_entries.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "mileage_entries_update_own"
  ON mileage_entries FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = mileage_entries.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

CREATE POLICY "mileage_entries_delete_own"
  ON mileage_entries FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      WHERE v.id = mileage_entries.vehicle_id
        AND v.owner_id = auth.uid()
    )
  );

-- ── updated_at ─────────────────────────────────────────────────────────────
CREATE TRIGGER mileage_entries_updated_at
  BEFORE UPDATE ON mileage_entries
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Update vehicles.odometer after insert ──────────────────────────────────
CREATE OR REPLACE FUNCTION update_vehicle_odometer()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE vehicles
  SET odometer = NEW.recorded_km
  WHERE id = NEW.vehicle_id
    AND odometer < NEW.recorded_km;
  RETURN NEW;
END;
$$;

CREATE TRIGGER mileage_entries_update_odometer
  AFTER INSERT OR UPDATE ON mileage_entries
  FOR EACH ROW EXECUTE FUNCTION update_vehicle_odometer();
