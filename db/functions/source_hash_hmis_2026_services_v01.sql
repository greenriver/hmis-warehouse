CREATE OR REPLACE FUNCTION source_hash_hmis_2026_services()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."ServicesID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateProvided", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RecordType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TypeProvided"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherTypeProvided", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MovingOnOtherType", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SubTypeProvided"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."FAAmount", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."FAStartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."FAEndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReferralOutcome"::text, E'\x1f') || E'\x1e' ||
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
