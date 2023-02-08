module Mutations
  class CreateBeds < BaseMutation
    argument :input, Types::HmisSchema::BedInput, required: true

    field :inventory, Types::HmisSchema::Inventory, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(input:)
      inventory = Hmis::Hud::Inventory.editable_by(current_user).find_by(id: input.inventory_id)
      errors = HmisErrors::Errors.new
      errors.add :inventory_id, :not_found unless inventory.present?

      unit = Hmis::Unit.find_by(id: input.unit_id)
      errors.add :unit_id, :not_found unless unit.present?

      # Validate all numbers are non-negative
      Hmis::Bed.bed_types.each do |bed_type, _|
        num = input.send(bed_type)
        errors.add bed_type, :out_of_range, message: 'must be positive' if num&.negative?
      end

      return { inventory: nil, errors: errors.errors } if errors.any?

      # Create Beds
      bed_args = []
      common = { user_id: hmis_user.user_id, created_at: Time.now, updated_at: Time.now }
      Hmis::Bed.bed_types.each do |bed_type, label|
        num_beds = input.send(bed_type)
        next unless num_beds&.positive?

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
      total_beds_added = 0
      Hmis::Bed.bed_types.each do |bed_type, _|
        previous = inventory.send(bed_type) || 0
        num_added = input.send(bed_type)
        if num_added&.positive?
          inventory.update(bed_type => previous + num_added)
          total_beds_added += num_added
        end
      end
      inventory.update(bed_inventory: inventory.bed_inventory + total_beds_added)

      {
        inventory: inventory,
        errors: [],
      }
    end
  end
end
