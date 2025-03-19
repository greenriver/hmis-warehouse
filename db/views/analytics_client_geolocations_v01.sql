SELECT
    id,
    client_id,
    source_type,
    source_id,
    located_on,
    lat,
    lon,
    -- collected_by,
    -- processed_at,
    created_at,
    updated_at,
    enrollment_id,
    located_at
FROM
    public.clh_locations
WHERE
    deleted_at IS NULL AND lat IS NOT NULL AND lon IS NOT NULL;
