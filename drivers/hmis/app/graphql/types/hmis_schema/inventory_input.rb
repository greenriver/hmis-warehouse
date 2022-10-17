module Types
  class HmisSchema::ProjectInput < BaseInputObject
    description 'HMIS Project CoC input'

    argument :project_id, ID, required: false
    # CONFIRM: saving the inventory record will validate that this makes for
    # a valid project_coc relation
    argument :coc_code, String, required: false, validates: { length: { maximum: 6 } }
    argument :household_type, HmisSchema::Enums::HouseholdType, required: false
    argument :availability, HmisSchema::Enums::Availability, required: false
    argument :unit_inventory, Float, required: false
    argument :bed_inventory, Float, required: false
    argument :ch_vet_bed_inventory, Float, required: false
    argument :youth_vet_bed_inventory, Float, required: false
    argument :ch_youth_vet_bed_inventory, Float, required: false
    argument :vet_bed_inventory, Float, required: false
    argument :ch_youth_bed_inventory, Float, required: false
    argument :youth_bed_inventory, Float, required: false
    argument :ch_bed_inventory, Float, required: false
    argument :other_bed_inventory, Float, required: false
    argument :es_bed_type, HmisSchema::Enums::BedType, required: false
    argument :inventory_start_date, GraphQL::Types::ISO8601Date, required: false
    argument :inventory_end_date, GraphQL::Types::ISO8601Date, required: false

    def to_params
      result = to_h.except(:project_id)

      result[:project_id] = Hmis::Hud::Project.viewable_by(current_user).find_by(id: project_id)&.project_id if project_id.present?

      # TODO validate coc code?

      result
    end
  end
end
