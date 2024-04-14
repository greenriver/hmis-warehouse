-- To update, run rails generate scenic:view hmis_households --replace
SELECT
  CONCAT(
    "Enrollment"."HouseholdID",
    ':',
    "Project"."ProjectID",
    ':',
    "Project"."data_source_id"
  ) AS id,
  "Enrollment"."HouseholdID",
  "Enrollment"."project_pk",
  "Project"."ProjectID",
  "Project"."data_source_id",
  MIN("Enrollment"."EntryDate") AS earliest_entry,
  CASE
    WHEN BOOL_OR("Exit"."ExitDate" IS NULL) THEN NULL
    ELSE MAX("Exit"."ExitDate")
  END AS latest_exit,
  BOOL_OR("Enrollment"."ProjectID" IS NULL) AS any_wip,
  NULL AS "DateDeleted",
  MAX("Enrollment"."DateUpdated") AS "DateUpdated",
  MIN("Enrollment"."DateCreated") AS "DateCreated"
FROM
  "Enrollment"
  LEFT OUTER JOIN "Exit" ON "Exit"."EnrollmentID" = "Enrollment"."EnrollmentID"
  AND "Exit"."data_source_id" = "Enrollment"."data_source_id"
  AND "Exit"."DateDeleted" IS NULL
  JOIN "Project" ON "Project"."DateDeleted" IS NULL
  AND "Project"."id" = "Enrollment"."project_pk"
WHERE
  "Enrollment"."DateDeleted" IS NULL
GROUP BY
  "Project"."data_source_id",
  "Project"."ProjectID",
  "Enrollment"."project_pk",
  "Enrollment"."HouseholdID";

CREATE RULE attempt_hmis_households_del AS ON DELETE TO hmis_households DO INSTEAD NOTHING;
CREATE RULE attempt_hmis_households_up AS ON UPDATE TO hmis_households DO INSTEAD NOTHING;
