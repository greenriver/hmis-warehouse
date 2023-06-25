(
  -- client related to project through enrollment
  SELECT
    "Client"."id" AS client_id,
    "Project"."id" AS project_id,
    "Enrollment"."id" AS enrollment_id
  FROM
    "Client"
    INNER JOIN "Enrollment" ON "Enrollment"."DateDeleted" IS NULL
    AND "Enrollment"."data_source_id" = "Client"."data_source_id"
    AND "Enrollment"."PersonalID" = "Client"."PersonalID"
    INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Project"."data_source_id" = "Enrollment"."data_source_id"
    AND "Project"."ProjectID" = "Enrollment"."ProjectID"
  WHERE
    "Client"."DateDeleted" IS NULL
)
UNION
(
  -- client related to project through wip
  SELECT
    "hmis_wips"."client_id" AS client_id,
    "hmis_wips"."project_id" AS project_id,
    "hmis_wips"."enrollment_id" AS enrollment_id
  FROM
    "hmis_wips"
)
