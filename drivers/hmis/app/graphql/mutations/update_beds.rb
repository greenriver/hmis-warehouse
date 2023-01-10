module Mutations
  class UpdateBeds < BaseMutation
    argument :inventory_id, ID, required: true
    argument :bed_ids, [ID], required: true
    argument :name, String, required: false
    argument :unit, ID, required: false

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, bed_ids:, name:, unit:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { inventory => nil, errors: [InputValidationError.new('Inventory record not found', attribute: 'inventory_id')] } unless inventory.present?

      return { inventory => inventory, errors: [] } unless bed_ids.any?

      inventory.beds.where(id: bed_ids).update(name: name) if name.present?
      inventory.beds.where(id: bed_ids).update(unit: unit) if unit.present?

      { inventory => inventory, errors: [] }
    end
  end
end
