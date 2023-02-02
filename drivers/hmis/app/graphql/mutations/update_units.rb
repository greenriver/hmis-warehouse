module Mutations
  class UpdateUnits < BaseMutation
    argument :inventory_id, ID, required: true
    argument :unit_ids, [ID], required: true
    argument :name, String, required: false

    field :units, [Types::HmisSchema::Unit], null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(inventory_id:, unit_ids:, name:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { units: [], errors: [Errors::CustomValidationError.new(:inventory_id, :not_found)] } unless inventory.present?

      units = inventory.units.where(id: unit_ids)
      units.update_all(name: name, user_id: hmis_user.user_id, updated_at: Time.now)

      { units: units, errors: [] }
    end
  end
end
