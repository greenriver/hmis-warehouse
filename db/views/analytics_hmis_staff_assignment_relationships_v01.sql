SELECT
    id,
    name,
    --deleted_at
    created_at,
    updated_at
FROM
    public.hmis_staff_assignment_relationships
WHERE
    deleted_at IS NULL;
