SELECT id,
    name,
    custom_service_category_id,
    hud_record_type,
    hud_type_provided,
    "UserID",
    data_source_id,
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    supports_bulk_assignment
   FROM "CustomServiceTypes"
  WHERE ("DateDeleted" IS NULL)