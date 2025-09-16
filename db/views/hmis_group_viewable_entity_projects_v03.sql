-- rails generate scenic:view hmis_group_viewable_entity_projects --replace
-- V3 changes: add hmis project groups, enabling `Hmis::GroupViewableEntity.where(entity_type: "Hmis::ProjectGroup").last&.projects`
(
  -- projects
  SELECT
    "hmis_group_viewable_entities"."id" AS group_viewable_entity_id,
    NULL as organization_id,
    "hmis_group_viewable_entities"."entity_id" AS project_id
  FROM
    "hmis_group_viewable_entities"
  WHERE
    "hmis_group_viewable_entities"."entity_type" = 'Hmis::Hud::Project'
    AND "hmis_group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects through organization
  SELECT
    "hmis_group_viewable_entities"."id" AS group_viewable_entity_id,
    "Organization"."id" AS organization_id,
    "Project"."id" AS project_id
  FROM
    "hmis_group_viewable_entities"
    INNER JOIN "Organization" ON "Organization"."DateDeleted" IS NULL
    AND "Organization"."id" = "hmis_group_viewable_entities"."entity_id"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Organization"."data_source_id" = "Project"."data_source_id"
    AND "Organization"."OrganizationID" = "Project"."OrganizationID"
  WHERE
    "hmis_group_viewable_entities"."entity_type" = 'Hmis::Hud::Organization'
    AND "hmis_group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects through project groups
  SELECT
    "hmis_group_viewable_entities"."id" AS group_viewable_entity_id,
    NULL AS organization_id,
    "hmis_project_project_groups"."project_id" AS project_id
  FROM
    "hmis_group_viewable_entities"
    INNER JOIN "hmis_project_groups" ON "hmis_project_groups"."deleted_at" IS NULL
    AND "hmis_project_groups"."id" = "hmis_group_viewable_entities"."entity_id"
    INNER JOIN "hmis_project_project_groups" ON "hmis_project_project_groups"."hmis_project_group_id" = "hmis_project_groups"."id"
  WHERE
    "hmis_group_viewable_entities"."entity_type" = 'Hmis::ProjectGroup'
    AND "hmis_group_viewable_entities"."deleted_at" IS NULL
)
UNION
(
  -- projects and organization through data_source
  SELECT
    "hmis_group_viewable_entities"."id" AS group_viewable_entity_id,
    "Organization"."id" as organization_id,
    "Project"."id" AS project_id
  FROM
    "hmis_group_viewable_entities"
    INNER JOIN "data_sources" ON "data_sources"."deleted_at" IS NULL
    AND "data_sources"."id" = "hmis_group_viewable_entities"."entity_id"
    LEFT JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "data_sources"."id" = "Project"."data_source_id"
    LEFT JOIN "Organization" ON "Organization"."DateDeleted" IS NULL
    AND "data_sources"."id" = "Organization"."data_source_id"
  WHERE
    "hmis_group_viewable_entities"."entity_type" = 'GrdaWarehouse::DataSource'
    AND "hmis_group_viewable_entities"."deleted_at" IS NULL
)
