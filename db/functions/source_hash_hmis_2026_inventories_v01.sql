CREATE OR REPLACE FUNCTION source_hash_hmis_2026_inventories()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."InventoryID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CoCCode", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HouseholdType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Availability"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UnitInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."BedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CHVetBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."YouthVetBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VetBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CHYouthBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."YouthBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CHBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherBedInventory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ESBedType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InventoryStartDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InventoryEndDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
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
