SELECT id,
    use,
    system,
    value,
    notes,
    "ContactPointID",
    "PersonalID",
    "UserID",
    data_source_id,
    "DateCreated",
    "DateUpdated",
    "DateDeleted"
   FROM "CustomClientContactPoint"
  WHERE ("DateDeleted" IS NULL)