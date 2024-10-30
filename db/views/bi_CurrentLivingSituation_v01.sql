 SELECT "CurrentLivingSituation".id AS "CurrentLivingSitID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "CurrentLivingSituation"."InformationDate",
    "CurrentLivingSituation"."CurrentLivingSituation",
    "CurrentLivingSituation"."VerifiedBy",
    "CurrentLivingSituation"."LeaveSituation14Days",
    "CurrentLivingSituation"."SubsequentResidence",
    "CurrentLivingSituation"."ResourcesToObtain",
    "CurrentLivingSituation"."LeaseOwn60Day",
    "CurrentLivingSituation"."MovedTwoOrMore",
    "CurrentLivingSituation"."LocationDetails",
    "CurrentLivingSituation"."DateCreated",
    "CurrentLivingSituation"."DateUpdated",
    "CurrentLivingSituation"."UserID",
    "CurrentLivingSituation"."DateDeleted",
    "CurrentLivingSituation"."ExportID",
    "CurrentLivingSituation".data_source_id,
    source_clients.id AS demographic_id
   FROM "CurrentLivingSituation"
     JOIN "Enrollment" ON "CurrentLivingSituation".data_source_id = "Enrollment".data_source_id AND "CurrentLivingSituation"."EnrollmentID"::text = "Enrollment"."EnrollmentID"::text AND "Enrollment"."DateDeleted" IS NULL
     LEFT JOIN "Exit" ON "Enrollment".data_source_id = "Exit".data_source_id AND "Enrollment"."EnrollmentID"::text = "Exit"."EnrollmentID"::text AND "Exit"."DateDeleted" IS NULL
     JOIN "Client" source_clients ON "CurrentLivingSituation".data_source_id = source_clients.data_source_id AND "CurrentLivingSituation"."PersonalID"::text = source_clients."PersonalID"::text AND source_clients."DateDeleted" IS NULL
     JOIN warehouse_clients ON source_clients.id = warehouse_clients.source_id
     JOIN "Client" destination_clients ON destination_clients.id = warehouse_clients.destination_id AND destination_clients."DateDeleted" IS NULL
  WHERE "Exit"."ExitDate" IS NULL OR "Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval) AND "CurrentLivingSituation"."DateDeleted" IS NULL;