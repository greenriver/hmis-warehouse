-- To update, run rails generate scenic:view hmis_restricted_client_enrollments --replace
--
-- One row per (restricted client, enrollment), resolving the PersonalID/data_source_id link between
-- Client and Enrollment so callers can filter either model on a plain primary key.
--
-- enrollment_id and project_id may be NULL for unenrolled restricted clients.
-- This is what keeps unenrolled restricted clients hidden from everyone.
SELECT
  "hmis_restricted_records"."restrictable_id" AS client_id,
  "Enrollment"."id" AS enrollment_id,
  "Enrollment"."project_pk" AS project_id,
  "hmis_restricted_records"."data_source_id" AS data_source_id
FROM
  "hmis_restricted_records"
  INNER JOIN "Client" ON "Client"."DateDeleted" IS NULL
  AND "Client"."id" = "hmis_restricted_records"."restrictable_id"
  AND "Client"."data_source_id" = "hmis_restricted_records"."data_source_id"
  -- LEFT OUTER JOIN to allow for unenrolled restricted clients (enrollment_id and project_id are NULL).
  -- Joined on project_pk rather than ProjectID so that WIP enrollments are included.
  LEFT OUTER JOIN "Enrollment" ON "Enrollment"."DateDeleted" IS NULL
  AND "Enrollment"."PersonalID" = "Client"."PersonalID"
  AND "Enrollment"."data_source_id" = "Client"."data_source_id"
WHERE
  "hmis_restricted_records"."restrictable_type" = 'Hmis::Hud::Client'
  AND "hmis_restricted_records"."deleted_at" IS NULL;
