SELECT
  targets.project_id,
  group_viewable_entities.access_group_id
FROM
  group_viewable_entities
  JOIN (
    SELECT
      "Project"."data_source_id" AS data_source_id,
      "Project"."id" AS project_id,
      "Organization"."id" AS organization_id,
      "project_groups"."id" AS project_group_id
    FROM
      "Project"
      LEFT OUTER JOIN "Organization" ON "Organization"."DateDeleted" IS NULL
      AND "Organization"."data_source_id" = "Project"."data_source_id"
      AND "Organization"."OrganizationID" = "Project"."OrganizationID"
      LEFT OUTER JOIN "project_project_groups" ON "project_project_groups"."project_id" = "Project"."id"
      LEFT OUTER JOIN "project_groups" ON "project_groups"."deleted_at" IS NULL
      AND "project_groups"."id" = "project_project_groups"."project_group_id"
    WHERE
      "Project"."DateDeleted" IS NULL
  ) targets ON group_viewable_entities.deleted_at IS NULL
  AND (
    (
      group_viewable_entities.entity_type = 'GrdaWarehouse::DataSource'
      AND group_viewable_entities.entity_id = targets.data_source_id
    )
    OR (
      group_viewable_entities.entity_type = 'GrdaWarehouse::Hud::Project'
      AND group_viewable_entities.entity_id = targets.project_id
    )
    OR (
      group_viewable_entities.entity_type = 'GrdaWarehouse::Hud::Organization'
      AND group_viewable_entities.entity_id = targets.organization_id
    )
    OR (
      (
        group_viewable_entities.entity_type = 'GrdaWarehouse::ProjectAccessGroup'
        OR group_viewable_entities.entity_type = 'GrdaWarehouse::ProjectGroup'
      )
      AND group_viewable_entities.entity_id = targets.project_group_id
    )
  )
WHERE
  "group_viewable_entities"."deleted_at" IS NULL
  AND "group_viewable_entities"."collection_id" IS NULL
GROUP BY
  targets.project_id,
  group_viewable_entities.access_group_id;

CREATE RULE attempt_project_access_group_members_del AS ON DELETE TO project_access_group_members DO INSTEAD NOTHING;

CREATE RULE attempt_project_access_group_members_up AS ON UPDATE TO project_access_group_members DO INSTEAD NOTHING;
