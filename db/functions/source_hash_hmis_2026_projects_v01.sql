CREATE OR REPLACE FUNCTION source_hash_hmis_2026_projects()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OrganizationID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectCommonName", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."OperatingStartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."OperatingEndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ContinuumProject"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HousingType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RRHSubType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ResidentialAffiliation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TargetPopulation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HOPWAMedAssistedLivingFac"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PITCount"::text, E'\x1f') || E'\x1e' ||
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
