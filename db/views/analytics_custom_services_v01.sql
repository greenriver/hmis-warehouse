SELECT id,
    "CustomServiceID",
    "EnrollmentID",
    "PersonalID",
    "UserID",
    "DateProvided",
    data_source_id,
    custom_service_type_id,
    service_name,
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    "FAAmount",
    "FAStartDate",
    "FAEndDate"
   FROM "CustomServices"
  WHERE ("DateDeleted" IS NULL)