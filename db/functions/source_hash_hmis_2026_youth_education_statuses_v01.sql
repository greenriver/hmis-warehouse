CREATE OR REPLACE FUNCTION source_hash_hmis_2026_youth_education_statuses()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."YouthEducationStatusID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CurrentSchoolAttend"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MostRecentEdStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CurrentEdStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DataCollectionStage"::text, E'\x1f') || E'\x1e' ||
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
