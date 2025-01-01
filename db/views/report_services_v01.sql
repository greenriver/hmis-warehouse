      SELECT "Services"."ServicesID",
      "Services"."EnrollmentID" AS "ProjectEntryID",
      "Services"."PersonalID",
      "Services"."DateProvided",
      "Services"."RecordType",
      "Services"."TypeProvided",
      "Services"."OtherTypeProvided",
      "Services"."SubTypeProvided",
      "Services"."FAAmount",
      "Services"."ReferralOutcome",
      "Services"."DateCreated",
      "Services"."DateUpdated",
      "Services"."UserID",
      "Services"."DateDeleted",
      "Services"."ExportID",
      "Services".data_source_id,
      "Services".id,
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("Services"
       JOIN "Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Services"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Services"."DateDeleted" IS NULL);
