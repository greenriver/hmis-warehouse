module Mutations
  class DeleteInventory < BaseMutation
    argument :id, ID, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:)
      record = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: id)
      default_delete_record(record: record, field_name: :inventory)
    end
  end
end
