(
  -- projects
  SELECT
    "group_viewable_entities"."id" AS group_viewable_entity_id,
    "Project"."id" AS project_id
  FROM
    "group_viewable_entities"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Project"."id" = "group_viewable_entities"."entity_id"
  WHERE
    "group_viewable_entities"."entity_type" = 'Hmis::Hud::Project'
    AND "group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects through organization
  SELECT
    "group_viewable_entities"."id" AS group_viewable_entity_id,
    "Project"."id" AS project_id
  FROM
    "group_viewable_entities"
    INNER JOIN "Organization" ON "Organization"."DateDeleted" IS NULL
    AND "Organization"."id" = "group_viewable_entities"."entity_id"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Organization"."data_source_id" = "Project"."data_source_id"
    AND "Organization"."OrganizationID" = "Project"."OrganizationID"
  WHERE
    "group_viewable_entities"."entity_type" = 'Hmis::Hud::Organization'
    AND "group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects through data_source
  SELECT
    "group_viewable_entities"."id" AS group_viewable_entity_id,
    "Project"."id" AS project_id
  FROM
    "group_viewable_entities"
    INNER JOIN "data_sources" ON "data_sources"."deleted_at" IS NULL
    AND "data_sources"."id" = "group_viewable_entities"."entity_id"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "data_sources"."id" = "Project"."data_source_id"
  WHERE
    "group_viewable_entities"."entity_type" = 'GrdaWarehouse::DataSource'
    AND "group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects through project_groups
  SELECT
    "group_viewable_entities"."id" AS group_viewable_entity_id,
    "Project"."id" AS project_id
  FROM
    "group_viewable_entities"
    INNER JOIN "project_groups" ON "project_groups"."deleted_at" IS NULL
    AND "project_groups"."id" = "group_viewable_entities"."entity_id"
    INNER JOIN "project_project_groups" ON "project_project_groups"."project_group_id" = "project_groups"."id"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Project"."id" = "project_project_groups"."project_id"
  WHERE
    "group_viewable_entities"."entity_type" = 'GrdaWarehouse::ProjectGroup'
    AND "group_viewable_entities"."deleted_at" IS NULL
)
