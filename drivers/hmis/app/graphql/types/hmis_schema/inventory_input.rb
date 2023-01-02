module Types
  class HmisSchema::InventoryInput < BaseInputObject
    def self.source_type
      HmisSchema::Inventory
    end

    hud_argument :project_id, ID
    hud_argument :coc_code, String
    hud_argument :household_type, HmisSchema::Enums::Hud::HouseholdType
    hud_argument :availability, HmisSchema::Enums::Hud::Availability
    hud_argument :unit_inventory
    hud_argument :bed_inventory
    # hud_argument :ch_vet_bed_inventory
    # hud_argument :youth_vet_bed_inventory
    # hud_argument :vet_bed_inventory
    # hud_argument :ch_youth_bed_inventory
    # hud_argument :youth_bed_inventory
    # hud_argument :ch_bed_inventory
    # hud_argument :other_bed_inventory
    hud_argument :es_bed_type, HmisSchema::Enums::Hud::BedType
    hud_argument :inventory_start_date
    hud_argument :inventory_end_date

    def to_params
      result = to_h
      result[:project_id] = Hmis::Hud::Project.editable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      result
    end
  end
end
