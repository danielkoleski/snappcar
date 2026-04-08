-- Migration 007: device_tokens table for FCM push notifications

CREATE TABLE device_tokens (
  id                     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id             uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token                  text        NOT NULL,
  platform               text        NOT NULL CHECK (platform IN ('android', 'ios')),
  notifications_enabled  boolean     NOT NULL DEFAULT true,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),

  -- One token per device: prevent duplicate registrations
  CONSTRAINT device_tokens_token_unique UNIQUE (token)
);

-- ── Row-Level Security ──────────────────────────────────────────────────────
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_select_own"
  ON device_tokens FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "device_tokens_insert_own"
  ON device_tokens FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "device_tokens_update_own"
  ON device_tokens FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "device_tokens_delete_own"
  ON device_tokens FOR DELETE
  USING (profile_id = auth.uid());

-- ── updated_at ─────────────────────────────────────────────────────────────
CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
