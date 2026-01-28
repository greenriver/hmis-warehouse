SELECT unit_occupancy.id,
  unit_occupancy.unit_id,
  unit_occupancy.enrollment_id,
  active_range.start_date,
  active_range.end_date
FROM public.hmis_unit_occupancy unit_occupancy
LEFT JOIN public.hmis_active_ranges active_range 
  ON active_range.entity_type = 'Hmis::UnitOccupancy' 
  AND active_range.entity_id = unit_occupancy.id 
  AND active_range.deleted_at IS NULL
WHERE unit_occupancy.deleted_at IS NULL
