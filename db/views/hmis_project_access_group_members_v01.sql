-- This view finds project and access group relationships.
-- It includes access groups that relate to the project indirectly
-- (via organization, project groups, data sources, etc)
SELECT
  targets.project_id,
  hmis_group_viewable_entities.collection_id AS access_group_id
FROM
  hmis_group_viewable_entities
  JOIN (
    -- Gather all the related entities for each project:
    -- data source, organization, and project groups
    SELECT
      "Project"."data_source_id" AS data_source_id,
      "Project"."id" AS project_id,
      "Organization"."id" AS organization_id,
      "hmis_project_groups"."id" AS project_group_id
    FROM
      "Project"
      LEFT OUTER JOIN "Organization" ON "Organization"."DateDeleted" IS NULL
      AND "Organization"."data_source_id" = "Project"."data_source_id"
      AND "Organization"."OrganizationID" = "Project"."OrganizationID"
      LEFT OUTER JOIN "hmis_project_project_groups" ON "hmis_project_project_groups"."project_id" = "Project"."id"
      LEFT OUTER JOIN "hmis_project_groups" ON "hmis_project_groups"."deleted_at" IS NULL
      AND "hmis_project_groups"."id" = "hmis_project_project_groups"."hmis_project_group_id"
    WHERE
      "Project"."DateDeleted" IS NULL
  ) targets ON hmis_group_viewable_entities.deleted_at IS NULL
  -- Match access groups to projects through various entity relationships:
  AND (
    -- Direct data source access
    (
      hmis_group_viewable_entities.entity_type = 'GrdaWarehouse::DataSource'
      AND hmis_group_viewable_entities.entity_id = targets.data_source_id
    )
    -- Direct project access
    OR (
      hmis_group_viewable_entities.entity_type = 'Hmis::Hud::Project'
      AND hmis_group_viewable_entities.entity_id = targets.project_id
    )
    -- Access via organization
    OR (
      hmis_group_viewable_entities.entity_type = 'Hmis::Hud::Organization'
      AND hmis_group_viewable_entities.entity_id = targets.organization_id
    )
    -- Access via project groups
    OR (
      hmis_group_viewable_entities.entity_type = 'Hmis::ProjectGroup'
      AND hmis_group_viewable_entities.entity_id = targets.project_group_id
    )
  )
WHERE
  "hmis_group_viewable_entities"."deleted_at" IS NULL
  AND "hmis_group_viewable_entities"."collection_id" IS NOT NULL
GROUP BY
  targets.project_id,
  hmis_group_viewable_entities.collection_id;
