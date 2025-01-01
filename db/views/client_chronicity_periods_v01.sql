      SELECT dc.id AS client_id,
      LEAST(enr."EntryDate", dsb."InformationDate") AS chronic_start,
      COALESCE(ex."ExitDate", NULL::date) AS chronic_end
     FROM ((((("Client" dc
       JOIN warehouse_clients wc ON ((wc.destination_id = dc.id)))
       JOIN "Client" sc ON (((sc.id = wc.source_id) AND (sc."DateDeleted" IS NULL))))
       JOIN "Enrollment" enr ON ((((enr."PersonalID")::text = (sc."PersonalID")::text) AND (enr.data_source_id = sc.data_source_id) AND (enr."DateDeleted" IS NULL))))
       JOIN "Disabilities" dsb ON ((((dsb."EnrollmentID")::text = (enr."EnrollmentID")::text) AND (dsb.data_source_id = enr.data_source_id) AND (dsb."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ex ON ((((ex."EnrollmentID")::text = (enr."EnrollmentID")::text) AND (ex.data_source_id = enr.data_source_id) AND (ex."DateDeleted" IS NULL))))
    WHERE ((dc.data_source_id = 1) AND (dc."DateDeleted" IS NULL) AND ((enr."DisablingCondition" = 1) OR ((dsb."DisabilityResponse" = ANY (ARRAY[1, 2, 3])) AND ((dsb."DisabilityType" = ANY (ARRAY[6, 8])) OR (dsb."IndefiniteAndImpairs" = 1)))))
  UNION ALL
   SELECT "Client".id AS client_id,
      "Client".disability_verified_on AS chronic_start,
      NULL::date AS chronic_end
     FROM "Client"
    WHERE (("Client".disability_verified_on IS NOT NULL) AND ("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id = 1));
