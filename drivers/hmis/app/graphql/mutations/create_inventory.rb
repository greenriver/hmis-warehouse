module Mutations
  class CreateInventory < BaseMutation
    argument :input, Types::HmisSchema::InventoryInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true

    def resolve(input:)
      default_create_record(
        Hmis::Hud::Inventory,
        field_name: :inventory,
        id_field_name: :inventory_id,
        input: input,
      )
    end
  end
end
