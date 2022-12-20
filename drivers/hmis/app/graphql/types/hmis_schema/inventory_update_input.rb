module Types
  class HmisSchema::InventoryUpdateInput < BaseInputObject
    def self.source_type
      HmisSchema::Inventory
    end

    hud_argument :coc_code, String
    hud_argument :household_type, HmisSchema::Enums::Hud::HouseholdType
    hud_argument :availability, HmisSchema::Enums::Hud::Availability
    hud_argument :es_bed_type, HmisSchema::Enums::Hud::BedType
    hud_argument :inventory_start_date
    hud_argument :inventory_end_date

    def to_params
      to_h
    end
  end
end
