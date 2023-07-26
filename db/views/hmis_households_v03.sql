-- To update, run rails generate scenic:view hmis_households --replace

SELECT
  CONCAT("Enrollment"."HouseholdID", MAX("Project"."ProjectID"), MAX("Enrollment"."data_source_id")) AS id,
  "Enrollment"."HouseholdID" AS "HouseholdID",
  MAX("Project"."ProjectID") AS "ProjectID",
  MAX("Enrollment"."data_source_id") AS data_source_id,
  MIN("Enrollment"."EntryDate") AS earliest_entry,
  CASE WHEN BOOL_OR("Exit"."ExitDate" IS NULL) THEN
    NULL
  ELSE
    MAX("Exit"."ExitDate")
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
  LEFT OUTER JOIN "hmis_wips" ON "hmis_wips"."source_id" = "Enrollment"."id"
    AND "hmis_wips"."source_type" = 'Hmis::Hud::Enrollment'
  INNER JOIN "Project" ON "Project"."DateDeleted" IS NULL
    AND "Project"."DateDeleted" IS NULL
    AND ("Project"."id" = "hmis_wips"."project_id" OR "Project"."ProjectID" = "Enrollment"."ProjectID")
WHERE
  "Enrollment"."HouseholdID" IS NOT NULL
  AND "Enrollment"."DateDeleted" IS NULL
GROUP BY
  "Enrollment"."HouseholdID",
  "Project"."ProjectID",
  "Enrollment"."data_source_id";

CREATE RULE attempt_hmis_households_del AS ON DELETE TO hmis_households DO INSTEAD NOTHING;
CREATE RULE attempt_hmis_households_up AS ON UPDATE TO hmis_households DO INSTEAD NOTHING;
