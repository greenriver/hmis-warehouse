module Mutations
  class UpdateUnits < BaseMutation
    argument :inventory_id, ID, required: true
    argument :unit_ids, [ID], required: true
    argument :name, String, required: false

    field :units, [Types::HmisSchema::Unit], null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, unit_ids:, name:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { units: [], errors: [InputValidationError.new('Inventory record not found', attribute: 'inventory_id')] } unless inventory.present?

      units = inventory.units.where(id: unit_ids)
      units.update_all(name: name)

      { units: units, errors: [] }
    end
  end
end
