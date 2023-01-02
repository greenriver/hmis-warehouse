module Mutations
  class CreateBeds < BaseMutation
    argument :input, Types::HmisSchema::BedInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

    def resolve(input:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: input.inventory_id)
      errors = []
      errors << InputValidationError.new('Inventory record not found', attribute: 'inventory_id') unless inventory.present?

      unit = Hmis::Unit.find_by(id: input.unit_id)
      errors << InputValidationError.new('Unit not found', attribute: 'unit_id') unless unit.present?

      # Validate all numbers are non-negative
      Hmis::Bed.bed_types.each do |bed_type, _|
        num = input.send(bed_type)
        errors << InputValidationError.new('Must be non-negative', attribute: bed_type) unless num&.positive?
      end

      return { inventory: nil, errors: errors } if errors.any?

      # Create Beds
      bed_args = []
      common = { user_id: hmis_user.user_id, created_at: Time.now, updated_at: Time.now }
      Hmis::Bed.bed_types.each do |bed_type, label|
        num_beds = input.send(bed_type)
        (1..num_beds).each do |i|
          bed_args << {
            unit_id: unit.id,
            name: "#{label} #{i}",
            bed_type: bed_type,
            **common,
          }
        end
      end

      Hmis::Bed.insert_all(bed_args) if bed_args.any?

      # Update bed counts on Inventory record
      # FIXME: call update once
      total_beds_added = 0
      Hmis::Bed.bed_types.each do |bed_type, _|
        previous = inventory.send(bed_type) || 0
        num_added = input.send(bed_type) || 0
        inventory.update(bed_type => previous + num_added)
        total_beds_added += num_added
      end
      inventory.update(bed_inventory: inventory.bed_inventory + total_beds_added)

      {
        inventory: inventory,
        errors: nil,
      }
    end
  end
end
