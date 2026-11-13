-- Restriction applies to the whole warehouse identity, mirroring
-- GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader: a restricted
-- source client redacts its destination client and every sibling source merged into
-- that destination. One hop only, through non-deleted warehouse_clients rows.
WITH directly_restricted AS (
  SELECT "hmis_restricted_records"."restrictable_id" AS client_id
  FROM "hmis_restricted_records"
  WHERE "hmis_restricted_records"."restrictable_type" = 'Hmis::Hud::Client'
    AND "hmis_restricted_records"."deleted_at" IS NULL
),
restricted_destinations AS (
  SELECT DISTINCT "warehouse_clients"."destination_id" AS client_id
  FROM "warehouse_clients"
  JOIN directly_restricted
    ON directly_restricted.client_id IN ("warehouse_clients"."source_id", "warehouse_clients"."destination_id")
  WHERE "warehouse_clients"."deleted_at" IS NULL
),
restricted_clients AS (
  SELECT client_id FROM directly_restricted
  UNION
  SELECT client_id FROM restricted_destinations
  UNION
  SELECT "warehouse_clients"."source_id"
  FROM "warehouse_clients"
  JOIN restricted_destinations ON restricted_destinations.client_id = "warehouse_clients"."destination_id"
  WHERE "warehouse_clients"."deleted_at" IS NULL
)
SELECT "Client"."id",
  "Client"."data_source_id",
  "Client"."PersonalID",
  CASE WHEN restricted_clients.client_id IS NOT NULL THEN 'Redacted' ELSE "Client"."FirstName" END::character varying(150) AS "FirstName",
  CASE WHEN restricted_clients.client_id IS NOT NULL THEN 'Redacted' ELSE "Client"."MiddleName" END::character varying(150) AS "MiddleName",
  CASE WHEN restricted_clients.client_id IS NOT NULL THEN 'Redacted' ELSE "Client"."LastName" END::character varying(150) AS "LastName",
  CASE WHEN restricted_clients.client_id IS NOT NULL THEN 'Redacted' ELSE "Client"."NameSuffix" END::character varying(50) AS "NameSuffix",
  CASE WHEN restricted_clients.client_id IS NOT NULL THEN 'Redacted' ELSE "Client"."SSN" END AS "SSN",
  "Client"."DOB"
FROM "Client"
LEFT JOIN restricted_clients ON restricted_clients.client_id = "Client"."id"
WHERE "Client"."DateDeleted" IS NULL
