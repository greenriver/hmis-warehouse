module Mutations
  class CreateUnits < BaseMutation
    argument :input, Types::HmisSchema::UnitInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: input.inventory_id)
      return { inventory => nil, errors: [CustomValidationError.new(:inventory_id, :not_found)] } unless inventory.present?

      return { inventory => nil, errors: [CustomValidationError.new(:count, :out_of_range, message: 'must be positive')] } if input.count&.negative?

      # Create Units
      common = { user_id: hmis_user.user_id, created_at: Time.now, updated_at: Time.now }
      unit_args = (1..input.count).map do |i|
        {
          inventory_id: inventory.id,
          name: [input.prefix, i].compact.join(' '),
          **common,
        }
      end
      units = Hmis::Unit.insert_all(unit_args) if unit_args.any?

      # Update unit count on Inventory record
      inventory.update(unit_inventory: inventory.unit_inventory + units.count)

      {
        inventory: inventory,
        errors: [],
      }
    end
  end
end
