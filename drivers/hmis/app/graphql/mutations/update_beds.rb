module Mutations
  class UpdateBeds < BaseMutation
    argument :inventory_id, ID, required: true
    argument :bed_ids, [ID], required: true
    argument :name, String, required: false
    argument :unit, ID, required: false

    field :beds, [Types::HmisSchema::Bed], null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, bed_ids:, name: nil, unit: nil)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { beds: [], errors: [InputValidationError.new('Inventory record not found', attribute: 'inventory_id')] } unless inventory.present?

      beds = inventory.beds.where(id: bed_ids)
      beds.update_all(name: name) if name.present?
      beds.update_all(unit_id: unit.to_i) if unit.present?

      { beds: beds, errors: [] }
    end
  end
end
