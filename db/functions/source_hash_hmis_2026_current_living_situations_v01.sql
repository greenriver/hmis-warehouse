CREATE OR REPLACE FUNCTION source_hash_hmis_2026_current_living_situations()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."CurrentLivingSitID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CurrentLivingSituation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CLSSubsidyType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VerifiedBy", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LeaveSituation14Days"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SubsequentResidence"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ResourcesToObtain"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LeaseOwn60Day"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MovedTwoOrMore"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LocationDetails", E'\x1f') || E'\x1e' ||
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
