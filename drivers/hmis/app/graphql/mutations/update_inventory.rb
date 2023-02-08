module Mutations
  class UpdateInventory < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::InventoryInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true

    def resolve(id:, input:)
      record = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: id)
      default_update_record(
        record: record,
        field_name: :inventory,
        input: input,
      )
    end
  end
end
