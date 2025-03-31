SELECT
    "hmis_staff_assignments"."id",
    "hmis_staff_assignments"."user_id",
    "hmis_staff_assignments"."household_id",
    "hmis_staff_assignment_relationships"."name",
    "hmis_staff_assignments"."data_source_id",
    "hmis_staff_assignments"."created_at",
    "hmis_staff_assignments"."updated_at"
FROM
    "public"."hmis_staff_assignments"
    LEFT OUTER JOIN "hmis_staff_assignment_relationships" ON "hmis_staff_assignment_relationships"."deleted_at" IS NULL
    AND "hmis_staff_assignment_relationships"."id" = "hmis_staff_assignments"."hmis_staff_assignment_relationship_id"
WHERE
    "hmis_staff_assignments"."deleted_at" IS NULL
