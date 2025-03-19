SELECT
    id,
    user_id,
    household_id,
    hmis_staff_assignment_relationship_id,
    data_source_id,
    --deleted_at
    created_at,
    updated_at
FROM
    public.hmis_staff_assignments
WHERE
    deleted_at IS NULL;
