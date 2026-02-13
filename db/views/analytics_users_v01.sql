SELECT id,
    "UserID",
    "UserFirstName",
    "UserLastName",
    "UserPhone",
    "UserExtension",
    "UserEmail",
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    "ExportID",
    data_source_id,
    pending_date_deleted,
    source_hash
   FROM "User"
  WHERE ("DateDeleted" IS NULL)