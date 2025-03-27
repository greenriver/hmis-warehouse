SELECT id,
  cohort_id,
  client_id,
  created_at,
  updated_at
FROM cohort_clients
WHERE deleted_at IS NULL
