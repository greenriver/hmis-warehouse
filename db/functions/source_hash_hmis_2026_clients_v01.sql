CREATE OR REPLACE FUNCTION source_hash_hmis_2026_clients()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."FirstName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MiddleName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LastName", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NameSuffix", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NameDataQuality"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSN", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSNDataQuality", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DOB", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DOBDataQuality", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Sex"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AmIndAKNative"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Asian"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."BlackAfAmerican"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MidEastNAfrican"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NativeHIPacific"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."White"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RaceNone"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AdditionalRaceEthnicity", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VeteranStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."YearEnteredService"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."YearSeparated"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WorldWarII"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."KoreanWar"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VietnamWar"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DesertStorm"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AfghanistanOEF"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IraqOIF"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IraqOND"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherTheater"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MilitaryBranch"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DischargeStatus"::text, E'\x1f') || E'\x1e' ||
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
