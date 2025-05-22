SELECT
    "hmis_staff_assignments"."id",
    "hmis_staff_assignments"."user_id",
    "hmis_staff_assignments"."household_id",
    "hmis_staff_assignment_relationships"."name",
    "hmis_staff_assignments"."data_source_id",
    "hmis_staff_assignments"."created_at",
    "hmis_staff_assignments"."updated_at",
    -- include deleted assignments for reporting, because they are still relevant to understanding who was assigned to the household
    "hmis_staff_assignments"."deleted_at"
FROM
    "public"."hmis_staff_assignments"
    -- include assignments that pertain to deleted relationship types (eg "Case Manager") because we still want to report on the full history of assignments, even if that type is no longer in use
    LEFT OUTER JOIN "hmis_staff_assignment_relationships" ON "hmis_staff_assignment_relationships"."id" = "hmis_staff_assignments"."hmis_staff_assignment_relationship_id"
