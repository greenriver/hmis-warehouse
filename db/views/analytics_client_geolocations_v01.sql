SELECT
    id,
    client_id,
    source_type,
    source_id,
    located_on,
    lat,
    lon,
    -- For HMIS-collected Locations collected_by gets filled as the Project Name. However they are tied to an Enrollment via source_id/source_type`, so the project name is redundant
    -- collected_by,
    -- processed_at,
    created_at,
    updated_at,
    -- legacy field
    -- enrollment_id,
    located_at
FROM
    public.clh_locations
WHERE
    deleted_at IS NULL AND lat IS NOT NULL AND lon IS NOT NULL;
