-- Migration 003: vehicles table and RLS

CREATE TABLE vehicles (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   uuid        REFERENCES profiles(id) ON DELETE SET NULL,
  make       text        NOT NULL,
  model      text        NOT NULL,
  year       integer     NOT NULL CHECK (year >= 1900 AND year <= 2100),
  color      text        NOT NULL,
  plate      text,
  fipe_code  text,
  odometer   integer     NOT NULL DEFAULT 0 CHECK (odometer >= 0),
  photo_url  text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vehicles_select_own"
  ON vehicles FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "vehicles_insert_own"
  ON vehicles FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "vehicles_update_own"
  ON vehicles FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "vehicles_delete_own"
  ON vehicles FOR DELETE
  USING (owner_id = auth.uid());

-- ── updated_at ─────────────────────────────────────────────────────────────
CREATE TRIGGER vehicles_updated_at
  BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
