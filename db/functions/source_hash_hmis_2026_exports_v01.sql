CREATE OR REPLACE FUNCTION source_hash_hmis_2026_exports()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."SourceType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceContactFirst", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceContactLast", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceContactPhone", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceContactExtension", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SourceContactEmail", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."ExportDate", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."ExportStartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."ExportEndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SoftwareName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SoftwareVersion", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CSVVersion", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ExportPeriodType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ExportDirective"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HashStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ImplementationID", E'\x1f'),
        'UTF8'
      )
    ),
    'hex'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
