SELECT id,
    project_group_id,
    project_id,
    created_at,
    updated_at,
    deleted_at
   FROM project_project_groups
  WHERE (deleted_at IS NULL)