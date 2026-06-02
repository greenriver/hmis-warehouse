CREATE OR REPLACE FUNCTION source_hash_hmis_2026_disabilities()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."DisabilitiesID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DisabilityType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DisabilityResponse"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IndefiniteAndImpairs"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TCellCountAvailable"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TCellCount"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TCellSource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ViralLoadAvailable"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ViralLoad"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ViralLoadSource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AntiRetroviral"::text, E'\x1f') || E'\x1e' ||
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
