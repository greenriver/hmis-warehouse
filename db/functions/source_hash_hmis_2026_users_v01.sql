CREATE OR REPLACE FUNCTION source_hash_hmis_2026_users()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."UserID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserFirstName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserLastName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserPhone", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserExtension", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserEmail", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateCreated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateUpdated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateDeleted", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f'),
        'UTF8'
      )
    ),
    'hex'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
