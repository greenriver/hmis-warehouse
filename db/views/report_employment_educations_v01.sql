
      SELECT "EmploymentEducation"."EmploymentEducationID",
      "EmploymentEducation"."EnrollmentID" AS "ProjectEntryID",
      "EmploymentEducation"."PersonalID",
      "EmploymentEducation"."InformationDate",
      "EmploymentEducation"."LastGradeCompleted",
      "EmploymentEducation"."SchoolStatus",
      "EmploymentEducation"."Employed",
      "EmploymentEducation"."EmploymentType",
      "EmploymentEducation"."NotEmployedReason",
      "EmploymentEducation"."DataCollectionStage",
      "EmploymentEducation"."DateCreated",
      "EmploymentEducation"."DateUpdated",
      "EmploymentEducation"."UserID",
      "EmploymentEducation"."DateDeleted",
      "EmploymentEducation"."ExportID",
      "EmploymentEducation".data_source_id,
      "EmploymentEducation".id,
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("EmploymentEducation"
       JOIN "Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("EmploymentEducation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("EmploymentEducation"."DateDeleted" IS NULL);
