SELECT id,
    version,
    identifier,
    role,
    status,
    definition,
    created_at,
    updated_at,
    title,
    deleted_at,
    external_form_object_key,
    backup_definition,
    managed_in_version_control
   FROM hmis_form_definitions
  WHERE (deleted_at IS NULL)