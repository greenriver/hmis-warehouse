CREATE OR REPLACE FUNCTION source_hash_hmis_2026_events()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."EventID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."EventDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Event"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProbSolDivRRResult"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReferralCaseManageAfter"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LocationCrisisOrPHHousing", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReferralResult"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."ResultDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
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
