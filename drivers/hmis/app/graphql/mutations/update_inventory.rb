module Mutations
  class UpdateInventory < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::InventoryUpdateInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(id:, input:)
      record = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: id)
      closes_inventory = record.present? && record.inventory_end_date.blank? && input.inventory_end_date.present?
      response = default_update_record(
        record: record,
        field_name: :inventory,
        input: input,
      )

      inventory = response[:inventory]
      return response unless inventory.present?

      close_related_records(inventory) if closes_inventory

      # TODO: warn if closing inventory that has beds that are currently assigned to clients

      response
    end

    def close_related_records(inventory)
      # TODO: close related Beds and Units?
    end
  end
end
