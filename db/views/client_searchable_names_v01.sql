(
  SELECT
    "Client"."id" as client_id,
    "Client".search_name_full AS full_name,
    "Client".search_name_last AS last_name,
    'primary' as "name_type"
  FROM
    "Client"
  WHERE
    "Client"."DateDeleted" IS NULL
)
UNION
(
  SELECT
    "Client"."id" as client_id,
    "CustomClientName".search_name_full AS full_name,
    "CustomClientName".search_name_full AS last_name,
    CASE WHEN "CustomClientName".primary THEN 'primary' ELSE 'secondary' END AS "name_type"
  FROM
    "CustomClientName"
  JOIN "Client" ON "Client"."PersonalID" = "CustomClientName"."PersonalID"
    AND "Client"."data_source_id" = "CustomClientName"."data_source_id"
  WHERE
    "CustomClientName"."DateDeleted" IS NULL
)
