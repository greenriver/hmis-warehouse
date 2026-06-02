CREATE OR REPLACE FUNCTION source_hash_hmis_2026_health_and_dvs()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."HealthAndDVID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DomesticViolenceSurvivor"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WhenOccurred"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CurrentlyFleeing"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GeneralHealthStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DentalHealthStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MentalHealthStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PregnancyStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DueDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
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
