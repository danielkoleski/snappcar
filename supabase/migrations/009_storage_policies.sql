-- Migration 009: Storage bucket policies for invoices and vehicle-photos
--
-- Buckets must be created first via Supabase Dashboard or CLI:
--   supabase storage create invoices --private
--   supabase storage create vehicle-photos --private
--
-- These policies enforce that each user can only access files
-- stored under their own auth.uid() folder.

-- ── invoices bucket ────────────────────────────────────────────────────────
CREATE POLICY "invoices_storage_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'invoices'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "invoices_storage_select_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'invoices'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "invoices_storage_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'invoices'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── vehicle-photos bucket ──────────────────────────────────────────────────
CREATE POLICY "vehicle_photos_storage_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'vehicle-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "vehicle_photos_storage_select_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'vehicle-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "vehicle_photos_storage_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'vehicle-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
