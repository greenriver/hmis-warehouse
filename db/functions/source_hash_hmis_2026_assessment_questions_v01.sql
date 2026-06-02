CREATE OR REPLACE FUNCTION source_hash_hmis_2026_assessment_questions()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."AssessmentQuestionID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AssessmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AssessmentQuestionGroup", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AssessmentQuestionOrder"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AssessmentQuestion", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AssessmentAnswer", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateCreated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateUpdated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateDeleted", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f'),
        'UTF8'
      )
    ),
    'hex'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
