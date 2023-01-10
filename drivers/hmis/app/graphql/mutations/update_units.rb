module Mutations
  class UpdateUnits < BaseMutation
    argument :inventory_id, ID, required: true
    argument :unit_ids, [ID], required: true
    argument :name, String, required: false

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, unit_ids:, name:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { inventory => nil, errors: [InputValidationError.new('Inventory record not found', attribute: 'inventory_id')] } unless inventory.present?

      return { inventory => inventory, errors: [] } unless unit_ids.any? && name.present?

      inventory.units.where(id: unit_ids).update(name: name)

      { inventory => inventory, errors: [] }
    end
  end
end
