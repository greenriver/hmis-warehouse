SELECT
    id,
    note,
    created_at,
    updated_at,
    deleted_at, -- include deleted alerts for reporting
    expiration_date,
    created_by_id,
    client_id,
    priority
FROM public.hmis_client_alerts;
