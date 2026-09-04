SELECT "Client"."id",
  "Client"."data_source_id",
  "Client"."PersonalID",
  CASE WHEN "hmis_restricted_records"."id" IS NOT NULL THEN 'Redacted' ELSE "Client"."FirstName" END::character varying(150) AS "FirstName",
  CASE WHEN "hmis_restricted_records"."id" IS NOT NULL THEN 'Redacted' ELSE "Client"."MiddleName" END::character varying(150) AS "MiddleName",
  CASE WHEN "hmis_restricted_records"."id" IS NOT NULL THEN 'Redacted' ELSE "Client"."LastName" END::character varying(150) AS "LastName",
  CASE WHEN "hmis_restricted_records"."id" IS NOT NULL THEN 'Redacted' ELSE "Client"."NameSuffix" END::character varying(50) AS "NameSuffix",
  CASE WHEN "hmis_restricted_records"."id" IS NOT NULL THEN 'Redacted' ELSE "Client"."SSN" END::character varying AS "SSN",
  "Client"."DOB"
FROM "Client"
LEFT JOIN "hmis_restricted_records"
  ON "hmis_restricted_records"."restrictable_type" = 'Hmis::Hud::Client'
  AND "hmis_restricted_records"."restrictable_id" = "Client"."id"
  AND "hmis_restricted_records"."deleted_at" IS NULL
WHERE "Client"."DateDeleted" is NULL
