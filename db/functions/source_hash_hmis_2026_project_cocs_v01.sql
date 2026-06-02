CREATE OR REPLACE FUNCTION source_hash_hmis_2026_project_cocs()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."ProjectCoCID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CoCCode", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Geocode", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Address1", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Address2", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."City", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."State", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Zip", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GeographyType"::text, E'\x1f') || E'\x1e' ||
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
