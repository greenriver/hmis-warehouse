module Mutations
  class UpdateBeds < BaseMutation
    argument :inventory_id, ID, required: true
    argument :bed_ids, [ID], required: true
    argument :name, String, required: false
    argument :gender, String, required: false
    argument :unit, ID, required: false

    field :beds, [Types::HmisSchema::Bed], null: false
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(inventory_id:, bed_ids:, name: nil, gender: nil, unit: nil)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: inventory_id)
      return { beds: [], errors: [HmisErrors::Error.new(:inventory_id, :not_found)] } unless inventory.present?

      beds = inventory.beds.where(id: bed_ids)
      common = { user_id: hmis_user.user_id, updated_at: Time.now }
      beds.update_all(gender: gender, name: name, **common)
      beds.update_all(unit_id: unit.to_i, **common) if unit.present?

      { beds: beds, errors: [] }
    end
  end
end
