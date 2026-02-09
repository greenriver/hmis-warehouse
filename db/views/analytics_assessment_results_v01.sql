SELECT id,
    "AssessmentResultID",
    "AssessmentID",
    "EnrollmentID",
    "PersonalID",
    "AssessmentResultType",
    "AssessmentResult",
    "DateCreated",
    "DateUpdated",
    "UserID",
    "DateDeleted",
    "ExportID",
    data_source_id,
    pending_date_deleted,
    source_hash
   FROM "AssessmentResults"
  WHERE ("DateDeleted" IS NULL)