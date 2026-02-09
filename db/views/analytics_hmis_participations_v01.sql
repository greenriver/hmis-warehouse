SELECT id,
    "HMISParticipationID",
    "ProjectID",
    "HMISParticipationType",
    "HMISParticipationStatusStartDate",
    "HMISParticipationStatusEndDate",
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    "UserID",
    "ExportID",
    data_source_id,
    pending_date_deleted,
    source_hash
   FROM "HMISParticipation"
  WHERE ("DateDeleted" IS NULL)