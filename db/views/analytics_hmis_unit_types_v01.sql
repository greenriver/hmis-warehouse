SELECT id,
  created_at,
  updated_at,
  description
FROM public.hmis_unit_types
WHERE deleted_at IS NULL
