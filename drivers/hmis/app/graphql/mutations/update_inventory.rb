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

    def create_errors(inventory, input)
      errors = []

      project_start = inventory.project.operating_start_date
      project_end = inventory.project.operating_end_date

      # validate start date
      if project_start && project_end && input.inventory_start_date && !input.inventory_start_date.between?(project_start, project_end)
        errors << InputValidationError.new("Inventory start date must be within project operating period (#{project_start.strftime('%m/%d/%Y')}-#{project_end.strftime('%m/%d/%Y')})", attribute: 'inventory_start_date')
      elsif project_start && input.inventory_start_date && input.inventory_start_date.before?(project_start)
        errors << InputValidationError.new("Inventory start date must be on or after project start date (#{project_start.strftime('%m/%d/%Y')})", attribute: 'inventory_start_date')
      end

      # validate end date
      if project_start && project_end && input.inventory_end_date && !input.inventory_end_date.between?(project_start, project_end)
        errors << InputValidationError.new("Inventory end date must be within project operating period (#{project_start.strftime('%m/%d/%Y')}-#{project_end.strftime('%m/%d/%Y')})", attribute: 'inventory_end_date')
      elsif project_start && input.inventory_end_date && input.inventory_end_date.before?(project_start)
        errors << InputValidationError.new("Inventory end date must be after project start date (#{project_start.strftime('%m/%d/%Y')})", attribute: 'inventory_end_date')
      end

      errors
    end

    def close_related_records(inventory)
      # TODO: close related Beds and Units?
    end
  end
end
