SELECT
	*
FROM (
	SELECT
		"Services"."id" AS owner_id,
		'Hmis::Hud::Service' AS owner_type,
		"CustomServiceTypes"."id" AS custom_service_type_id,
		"EnrollmentID",
		"PersonalID",
		"DateProvided",
		"Services"."UserID",
		"Services"."DateCreated" AS "DateCreated",
		"Services"."DateUpdated" AS "DateUpdated",
		"Services"."DateDeleted" AS "DateDeleted",
		"Services"."data_source_id" AS "data_source_id"
	FROM
		"Services"
		JOIN "CustomServiceTypes" ON "CustomServiceTypes"."hud_record_type" = "Services"."RecordType"
			AND "CustomServiceTypes"."hud_type_provided" = "Services"."TypeProvided"
			AND "CustomServiceTypes"."DateDeleted" IS NULL) hud_services
UNION
SELECT
	id AS owner_id,
	'Hmis::Hud::CustomService' AS owner_type,
	"custom_service_type_id",
	"EnrollmentID",
	"PersonalID",
	"DateProvided",
	"UserID",
	"DateCreated",
	"DateUpdated",
	"DateDeleted",
	"data_source_id"
FROM
	"CustomServices"
