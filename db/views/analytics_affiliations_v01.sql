SELECT "AffiliationID",
    "ProjectID",
    "ResProjectID",
    "DateCreated",
    "DateUpdated",
    "UserID",
    "DateDeleted",
    "ExportID",
    data_source_id,
    id,
    source_hash,
    pending_date_deleted
   FROM "Affiliation"
  WHERE ("DateDeleted" IS NULL)