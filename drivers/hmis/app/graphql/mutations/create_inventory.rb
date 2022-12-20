module Mutations
  class CreateInventory < BaseMutation
    argument :input, Types::HmisSchema::InventoryInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      response = default_create_record(
        Hmis::Hud::Inventory,
        field_name: :inventory,
        id_field_name: :inventory_id,
        input: input,
      )

      inventory = response[:inventory]
      return response unless inventory.present?

      create_beds_and_units(inventory, input.beds_per_unit)

      response
    end

    def create_beds_and_units(inventory, beds_per_unit)
      return unless inventory.unit_inventory.positive?

      common = { user_id: hmis_user.user_id, created_at: Time.now, updated_at: Time.now }

      # Create Units

      unit_args = (1..inventory.unit_inventory).map do |i|
        {
          inventory_id: inventory.id,
          name: "Unit #{i}",
          **common,
        }
      end
      units = Hmis::Unit.insert_all(unit_args)

      # Create Beds

      bed_args = []
      unit_idx = 0
      beds_filled = 0
      Hmis::Bed.bed_types.each do |bed_type|
        num_beds = inventory.send(bed_type)
        next unless num_beds&.positive?

        (1..num_beds).each do |i|
          # Try to fill beds according to beds_per_unit.
          # If we have too many beds, puts all the remaining ones in the last unit.
          if beds_filled >= beds_per_unit && unit_idx < units.length - 1
            unit_idx += 1
            beds_filled = 0
          end

          beds_filled += 1

          bed_args << {
            unit_id: units[unit_idx]['id'],
            name: "#{bed_type.to_s.sub!('_bed_inventory', '').titleize} #{i}",
            bed_type: bed_type,
            **common,
          }
        end
      end
      Hmis::Bed.insert_all(bed_args) if bed_args.any?
    end

    def create_errors(inventory, input)
      errors = []

      # Must be at least 1 unit if there are any beds
      errors << InputValidationError.new('Unit count must be greater than zero', attribute: 'unit_inventory') if !input.unit_inventory&.positive? && input.bed_inventory&.positive?

      project_start = inventory.project&.operating_start_date
      project_end = inventory.project&.operating_end_date

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
  end
end
