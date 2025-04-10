SELECT
    id,
    note,
    created_at,
    updated_at,
    -- deleted_at,
    expiration_date,
    created_by_id,
    client_id,
    priority
FROM public.hmis_client_alerts
WHERE deleted_at IS NULL;
