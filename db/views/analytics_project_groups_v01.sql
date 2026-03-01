SELECT id,
    name,
    created_at,
    updated_at,
    deleted_at,
    options
   FROM project_groups
  WHERE (deleted_at IS NULL)