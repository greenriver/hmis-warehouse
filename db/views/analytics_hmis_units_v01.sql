SELECT id,
  created_at,
  updated_at,
  deleted_at, -- Unlike many other CE analytics views, we still export deleted units because we expect users will need to report on historical occupancy and availability over time
  user_id,
  hmis_unit_group_id
FROM public.hmis_units
WHERE hmis_unit_group_id IS NOT NULL -- the column is still nullable in our DB, but this should never be null, so we ensure it's not in the export
