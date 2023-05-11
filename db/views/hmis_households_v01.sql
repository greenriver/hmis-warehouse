-- To update, run rails generate scenic:view hmis_households --replace

SELECT
	"Enrollment"."HouseholdID" as id,
  "Enrollment"."HouseholdID" as "HouseholdID",
	MAX("Enrollment"."ProjectID") as "ProjectID",
  MAX("Enrollment"."data_source_id") as data_source_id,
	MIN("Enrollment"."EntryDate") as earliest_entry,
	CASE
		WHEN BOOL_OR("Exit"."ExitDate" is NULL) THEN NULL
		ELSE MAX("Exit"."ExitDate")
	END as latest_exit,
	BOOL_OR("Enrollment"."ProjectID" is NULL) as any_wip,
  NULL as "DateDeleted",
  MAX("Enrollment"."DateUpdated") as "DateUpdated",
  MIN("Enrollment"."DateCreated") as "DateCreated"
FROM
	"Enrollment"
	LEFT OUTER JOIN "Exit" ON "Exit"."EnrollmentID" = "Enrollment"."EnrollmentID"
	AND "Exit"."data_source_id" = "Enrollment"."data_source_id"
WHERE "Enrollment"."HouseholdID" is not NULL AND "Enrollment"."DateDeleted" IS NULL
GROUP BY "Enrollment"."HouseholdID";

CREATE RULE attempt_hmis_households_del AS ON DELETE TO hmis_households DO INSTEAD NOTHING;
CREATE RULE attempt_hmis_households_up AS ON UPDATE TO hmis_households DO INSTEAD NOTHING;
