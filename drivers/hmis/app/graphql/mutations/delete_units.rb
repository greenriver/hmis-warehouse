module Mutations
  class DeleteUnits < BaseMutation
    argument :inventory_id, ID, required: true
    argument :unit_ids, [ID], required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, unit_ids:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { inventory => nil, errors: [Errors::CustomValidationError.new(:inventory_id, :not_found)] } unless inventory.present?

      return { inventory => inventory, errors: [] } unless unit_ids.any?

      inventory.units.where(id: unit_ids).destroy_all

      { inventory => inventory, errors: [] }
    end
  end
end
