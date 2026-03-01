SELECT id,
    name,
    "UserID",
    data_source_id,
    "DateCreated",
    "DateUpdated",
    "DateDeleted"
   FROM "CustomServiceCategories"
  WHERE ("DateDeleted" IS NULL)