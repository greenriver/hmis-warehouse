-- To update, run rails generate scenic:view hmis_services --replace
(
	SELECT
		CAST(
			CONCAT('1', CAST("Services"."id" AS VARCHAR)) AS INT
		) AS id,
		"Services"."id" AS owner_id,
		'Hmis::Hud::Service' AS owner_type,
		"CustomServiceTypes"."id" AS custom_service_type_id,
		"enrollment_slug",
		"EnrollmentID",
		"PersonalID",
		"DateProvided",
		"Services"."UserID" :: varchar AS "UserID",
		"Services"."DateCreated" AS "DateCreated",
		"Services"."DateUpdated" AS "DateUpdated",
		"Services"."DateDeleted" AS "DateDeleted",
		"Services"."data_source_id" AS "data_source_id"
	FROM
		"Services" JOIN "CustomServiceTypes"
		ON "CustomServiceTypes"."slug" = "Services"."custom_service_type_slug"
		AND "CustomServiceTypes"."DateDeleted" IS NULL
	WHERE
		"Services"."DateDeleted" IS NULL
)
UNION
ALL (
	SELECT
		CAST(
			CONCAT('2', CAST("CustomServices".id AS VARCHAR)) AS INT
		) AS id,
		"CustomServices".id :: integer AS owner_id,
		'Hmis::Hud::CustomService' AS owner_type,
		"CustomServices"."custom_service_type_id",
		"CustomServices"."enrollment_slug",
		"CustomServices"."EnrollmentID",
		"CustomServices"."PersonalID",
		"CustomServices"."DateProvided",
		"CustomServices"."UserID",
		"CustomServices"."DateCreated",
		"CustomServices"."DateUpdated",
		"CustomServices"."DateDeleted",
		"CustomServices"."data_source_id"
	FROM
		"CustomServices"
	WHERE
		"CustomServices"."DateDeleted" IS NULL
)
