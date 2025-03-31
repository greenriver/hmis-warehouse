-- rename from custom_case_notes to hmis_case_notes
SELECT
    id,
    -- "CustomCaseNoteID" AS custom_case_note_id,
    "PersonalID" AS personal_id,
    "EnrollmentID" AS enrollment_id,
    data_source_id,
    content,
    "UserID" AS user_id,
    "DateCreated" AS date_created,
    "DateUpdated" AS date_updated,
    --"DateDeleted" AS date_deleted,
    information_date
FROM
    public."CustomCaseNote"
WHERE
    "DateDeleted" IS NULL;
