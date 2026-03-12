SELECT id,
    data_element_definition_id,
    owner_type,
    owner_id,
    value_float,
    value_integer,
    value_boolean,
    value_string,
    value_text,
    value_date,
    value_json,
    data_source_id,
    "UserID",
    "DateCreated",
    "DateUpdated",
    "DateDeleted"
   FROM "CustomDataElements"
  WHERE ("DateDeleted" IS NULL)