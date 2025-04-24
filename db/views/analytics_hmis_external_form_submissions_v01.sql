SELECT
    id,
    created_at,
    updated_at,
    submitted_at,
    spam_score,
    status,
    definition_id,
    object_key,
    -- raw_data,
    notes,
    enrollment_id
FROM
    public.hmis_external_form_submissions;
