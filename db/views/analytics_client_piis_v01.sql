SELECT "id",
  "data_source_id",
  "PersonalID",
  "FirstName",
  "MiddleName",
  "LastName",
  "NameSuffix",
  "SSN",
  "DOB"
FROM "Client"
WHERE "DateDeleted" is NULL
