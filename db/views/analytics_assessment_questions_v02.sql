SELECT "id",
  "AssessmentQuestionID",
  "AssessmentID",
  "EnrollmentID",
  "PersonalID",
  "AssessmentQuestionGroup",
  "AssessmentQuestionOrder",
  "AssessmentQuestion",
  COALESCE(
    (
      SELECT aal.response_text
      FROM assessment_answer_lookups aal
      WHERE aal.assessment_question = "AssessmentQuestions"."AssessmentQuestion"
        AND aal.response_code = "AssessmentQuestions"."AssessmentAnswer"
      ORDER BY aal.updated_at DESC
      LIMIT 1
    ), "AssessmentAnswer"
  ) AS "AssessmentAnswer",
  "AssessmentAnswer" as original_assessment_answer,
  "DateCreated",
  "DateUpdated",
  "UserID",
  "ExportID",
  "data_source_id"
FROM "AssessmentQuestions"
WHERE "DateDeleted" is NULL
