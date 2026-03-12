SELECT "EnrollmentCoCID",
    "EnrollmentID",
    "ProjectID",
    "PersonalID",
    "InformationDate",
    "CoCCode",
    "DataCollectionStage",
    "DateCreated",
    "DateUpdated",
    "UserID",
    "DateDeleted",
    "ExportID",
    data_source_id,
    id,
    "HouseholdID",
    source_hash,
    pending_date_deleted
   FROM "EnrollmentCoC"
  WHERE ("DateDeleted" IS NULL)