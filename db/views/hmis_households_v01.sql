-- To update, run rails generate scenic:view hmis_households --replace

SELECT
	"Enrollment"."HouseholdID" as id,
  "Enrollment"."HouseholdID" as "HouseholdID",
	MAX("Enrollment"."ProjectID") as "ProjectID",
  MAX("Enrollment"."data_source_id") as data_source_id,
	MIN("Enrollment"."EntryDate") as earliest_open,
	CASE
		WHEN BOOL_OR("Exit"."ExitDate" is NULL) THEN NULL
		ELSE MAX("Exit"."ExitDate")
	END as latest_exit,
	BOOL_OR("Enrollment"."ProjectID" is NULL) as any_wip,
  CASE
		WHEN BOOL_OR("Enrollment"."DateDeleted" is NULL) THEN NULL
		ELSE MAX("Enrollment"."DateDeleted")
	END as "DateDeleted",
  MAX("Enrollment"."DateUpdated") as "DateUpdated",
  MIN("Enrollment"."DateCreated") as "DateCreated"
FROM
	"Enrollment"
	LEFT OUTER JOIN "Exit" ON "Exit"."EnrollmentID" = "Enrollment"."EnrollmentID"
WHERE "Enrollment"."HouseholdID" is not NULL
GROUP BY "Enrollment"."HouseholdID"
