with nullable_lkp as (
  select distinct on (assessment_question, response_code) *
  from assessment_answer_lookups
  order by assessment_question,
    response_code,
    updated_at desc
)
SELECT "AssessmentQuestions"."id",
  "AssessmentQuestionID",
  "AssessmentID",
  "EnrollmentID",
  "PersonalID",
  "AssessmentQuestionGroup",
  "AssessmentQuestionOrder",
  "AssessmentQuestion",
  coalesce(aal.response_text, "AssessmentAnswer") as "AssessmentAnswer",
  "AssessmentAnswer" as original_assessment_answer,
  "DateCreated",
  "DateUpdated",
  "UserID",
  "ExportID",
  "AssessmentQuestions"."data_source_id"
FROM "AssessmentQuestions"
  left join nullable_lkp as aal on aal.assessment_question = "AssessmentQuestions"."AssessmentQuestion"
  and aal.response_code = "AssessmentQuestions"."AssessmentAnswer"
  and aal.data_source_id = "AssessmentQuestions"."data_source_id"
WHERE "DateDeleted" is NULL
