-- To update, run rails generate scenic:view hmis_households --replace
WITH tmp1 AS (
  (
    SELECT
      "Enrollment"."HouseholdID",
      "Project"."ProjectID",
      FALSE AS wip,
      "Project"."data_source_id",
      "Enrollment"."EntryDate",
      "Exit"."ExitDate",
      "Enrollment"."DateUpdated",
      "Enrollment"."DateCreated"
    FROM
      "Enrollment"
      LEFT OUTER JOIN "Exit" ON "Exit"."EnrollmentID" = "Enrollment"."EnrollmentID"
      AND "Exit"."data_source_id" = "Enrollment"."data_source_id"
      AND "Exit"."DateDeleted" IS NULL
      JOIN "Project" ON "Project"."DateDeleted" IS NULL
      AND "Project"."data_source_id" = "Enrollment"."data_source_id"
      AND "Project"."ProjectID" = "Enrollment"."ProjectID"
    WHERE
      "Enrollment"."DateDeleted" IS NULL
  )
  UNION
  ALL (
    SELECT
      "Enrollment"."HouseholdID",
      "Project"."ProjectID",
      TRUE AS wip,
      "Project"."data_source_id",
      "Enrollment"."EntryDate",
      "Exit"."ExitDate",
      "Enrollment"."DateUpdated",
      "Enrollment"."DateCreated"
    FROM
      "Enrollment"
      LEFT OUTER JOIN "Exit" ON "Exit"."EnrollmentID" = "Enrollment"."EnrollmentID"
      AND "Exit"."data_source_id" = "Enrollment"."data_source_id"
      AND "Exit"."DateDeleted" IS NULL
      JOIN "hmis_wips" ON "hmis_wips"."source_id" = "Enrollment"."id"
      AND "hmis_wips"."source_type" = 'Hmis::Hud::Enrollment'
      JOIN "Project" ON "Project"."DateDeleted" IS NULL
      AND "Project"."id" = "hmis_wips"."project_id"
    WHERE
      "Enrollment"."DateDeleted" IS NULL
      AND "Enrollment"."ProjectID" IS NULL
      -- The below line is the only change from v05 to v06.
      -- We need this since we added the acts_as_paranoid gem to the Hmis::Wip model
      AND "hmis_wips"."deleted_at" IS NULL
  )
)
SELECT
  CONCAT(
    "HouseholdID",
    ':',
    "ProjectID",
    ':',
    "data_source_id"
  ) AS id,
  "HouseholdID",
  "ProjectID",
  "data_source_id",
  MIN("EntryDate") AS earliest_entry,
  CASE
    WHEN BOOL_OR("ExitDate" IS NULL) THEN NULL
    ELSE MAX("ExitDate")
  END AS latest_exit,
  BOOL_OR(wip) AS any_wip,
  NULL AS "DateDeleted",
  MAX("DateUpdated") AS "DateUpdated",
  MIN("DateCreated") AS "DateCreated"
FROM
  tmp1
GROUP BY
  tmp1."HouseholdID",
  tmp1."ProjectID",
  tmp1."data_source_id";

CREATE RULE attempt_hmis_households_del AS ON DELETE TO hmis_households DO INSTEAD NOTHING;
CREATE RULE attempt_hmis_households_up AS ON UPDATE TO hmis_households DO INSTEAD NOTHING;
