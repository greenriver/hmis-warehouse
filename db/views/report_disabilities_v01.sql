
SELECT "Disabilities"."DisabilitiesID",
"Disabilities"."EnrollmentID" AS "ProjectEntryID",
"Disabilities"."PersonalID",
"Disabilities"."InformationDate",
"Disabilities"."DisabilityType",
"Disabilities"."DisabilityResponse",
"Disabilities"."IndefiniteAndImpairs",
"Disabilities"."DocumentationOnFile",
"Disabilities"."ReceivingServices",
"Disabilities"."PATHHowConfirmed",
"Disabilities"."PATHSMIInformation",
"Disabilities"."TCellCountAvailable",
"Disabilities"."TCellCount",
"Disabilities"."TCellSource",
"Disabilities"."ViralLoadAvailable",
"Disabilities"."ViralLoad",
"Disabilities"."ViralLoadSource",
"Disabilities"."DataCollectionStage",
"Disabilities"."DateCreated",
"Disabilities"."DateUpdated",
"Disabilities"."UserID",
"Disabilities"."DateDeleted",
"Disabilities"."ExportID",
"Disabilities".data_source_id,
"Disabilities".id,
"Enrollment".id AS enrollment_id,
source_clients.id AS demographic_id,
destination_clients.id AS client_id
FROM (((("Disabilities"
 JOIN "Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
 JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
 JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
 JOIN "Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Disabilities"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Disabilities"."DateDeleted" IS NULL);
