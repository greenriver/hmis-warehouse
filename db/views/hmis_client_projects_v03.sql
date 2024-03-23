(
  -- client related to project through enrollment
  SELECT
    "Client"."id" AS client_id,
    "Project"."id" AS project_id,
    "Enrollment"."id" AS enrollment_id,
    "Enrollment"."EnrollmentID",
    "Enrollment"."HouseholdID",
    "Enrollment"."data_source_id"
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
    "hmis_wips"."client_id"::integer AS client_id,
    "hmis_wips"."project_id"::integer AS project_id,
    "Enrollment"."id"::integer AS enrollment_id,
    "Enrollment"."EnrollmentID",
    "Enrollment"."HouseholdID",
    "Enrollment"."data_source_id"
  FROM
    "hmis_wips"
    INNER JOIN "Enrollment" ON "Enrollment"."DateDeleted" IS NULL
    AND "Enrollment"."id" = "hmis_wips"."source_id"
  WHERE
    "hmis_wips"."source_type" = 'Hmis::Hud::Enrollment'
    -- The below line is the only change from v02 to v03.
    -- We need this since we added the acts_as_paranoid gem to the Hmis::Wip model
    AND "hmis_wips"."deleted_at" IS NULL
)
