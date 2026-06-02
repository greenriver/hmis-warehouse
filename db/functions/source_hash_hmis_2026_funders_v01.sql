CREATE OR REPLACE FUNCTION source_hash_hmis_2026_funders()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."FunderID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Funder"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherFunder", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GrantID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."StartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."EndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
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
