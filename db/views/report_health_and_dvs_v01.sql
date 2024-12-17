      SELECT "HealthAndDV"."HealthAndDVID",
      "HealthAndDV"."EnrollmentID" AS "ProjectEntryID",
      "HealthAndDV"."PersonalID",
      "HealthAndDV"."InformationDate",
      "HealthAndDV"."DomesticViolenceVictim",
      "HealthAndDV"."WhenOccurred",
      "HealthAndDV"."CurrentlyFleeing",
      "HealthAndDV"."GeneralHealthStatus",
      "HealthAndDV"."DentalHealthStatus",
      "HealthAndDV"."MentalHealthStatus",
      "HealthAndDV"."PregnancyStatus",
      "HealthAndDV"."DueDate",
      "HealthAndDV"."DataCollectionStage",
      "HealthAndDV"."DateCreated",
      "HealthAndDV"."DateUpdated",
      "HealthAndDV"."UserID",
      "HealthAndDV"."DateDeleted",
      "HealthAndDV"."ExportID",
      "HealthAndDV".data_source_id,
      "HealthAndDV".id,
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("HealthAndDV"
       JOIN "Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("HealthAndDV"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("HealthAndDV"."DateDeleted" IS NULL);
