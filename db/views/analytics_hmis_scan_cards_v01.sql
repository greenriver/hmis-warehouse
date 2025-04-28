SELECT
  id,
  client_id,
  value,
  created_by_id,
  deleted_by_id,
  created_at,
  updated_at,
  deleted_at,
  expires_at
FROM "hmis_scan_card_codes"

-- Note: intentionally including deleted scan card codes to report on full history of scan card creation/deletion
