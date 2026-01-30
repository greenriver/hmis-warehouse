SELECT id,
  name,
  project_id,
  workflow_template_identifier AS waitlist_referral_template_identifier,
  -- if direct_referral_workflow_template_identifier is null, but workflow_template_identifier is not, return that for clarity
  COALESCE(direct_referral_workflow_template_identifier, workflow_template_identifier) AS direct_referral_template_identifier,
  created_at,
  updated_at,
  candidate_pool_id,
  unit_type_id
FROM public.hmis_unit_groups
WHERE deleted_at IS NULL
  AND unit_type_id IS NOT NULL -- the column is still nullable in our DB, but this should never be null, so we ensure it's not in the export
