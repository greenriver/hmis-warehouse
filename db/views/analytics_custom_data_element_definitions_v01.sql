SELECT id,
    owner_type,
    custom_service_type_id,
    field_type,
    key,
    label,
    repeats,
    data_source_id,
    "UserID",
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    show_in_summary,
    form_definition_identifier
   FROM "CustomDataElementDefinitions"
  WHERE ("DateDeleted" IS NULL)