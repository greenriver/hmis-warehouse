SELECT id,
    "CustomAssessmentID",
    "EnrollmentID",
    "PersonalID",
    "UserID",
    "AssessmentDate",
    "DataCollectionStage",
    data_source_id,
    "DateCreated",
    "DateUpdated",
    "DateDeleted",
    wip,
    lock_version
   FROM "CustomAssessments"
  WHERE ("DateDeleted" IS NULL)