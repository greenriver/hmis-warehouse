CREATE OR REPLACE FUNCTION source_hash_hmis_2026_hmis_participations()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."HMISParticipationID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HMISParticipationType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."HMISParticipationStatusStartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."HMISParticipationStatusEndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
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
