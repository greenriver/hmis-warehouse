module Mutations
  class DeleteInventory < BaseMutation
    argument :id, ID, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true

    def resolve(id:)
      record = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :inventory)
    end
  end
end
