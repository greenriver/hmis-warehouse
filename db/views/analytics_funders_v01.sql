SELECT "FunderID",
    "ProjectID",
    "Funder",
    "GrantID",
    "StartDate",
    "EndDate",
    "DateCreated",
    "DateUpdated",
    "UserID",
    "DateDeleted",
    "ExportID",
    data_source_id,
    id,
    source_hash,
    pending_date_deleted,
    "OtherFunder",
    manual_entry
   FROM "Funder"
  WHERE ("DateDeleted" IS NULL)