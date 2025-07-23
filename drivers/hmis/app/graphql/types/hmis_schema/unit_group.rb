###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::UnitGroup < Types::BaseObject
    # object is a Hmis::UnitGroup
    include Types::HmisSchema::HasUnits

    field :id, ID, null: false
    field :name, String, null: false
    field :capacity, Integer, null: false, description: 'Total number of units in the group'
    field :availability, Integer, null: false, description: 'Number of units in this group that are currently unoccupied'
    field :unit_types, [Types::HmisSchema::UnitTypeCapacity], null: false
    units_field

    # CE fields
    field :eligibility_requirements, [HmisSchema::CeMatchRule], null: true
    field :priority_scheme, HmisSchema::CeMatchRule, null: true
    field :workflow_template_identifier, String, null: true
    field :workflow_template_name, String, null: true
    field :direct_referral_entrypoint_name, String, null: true
    # TODO(#7538) resolve default contacts for workflow template

    def workflow_template_name
      object.workflow_template&.name
    end

    def direct_referral_entrypoint_name
      object.direct_referral_entrypoint&.name
    end

    def units(**args)
      # No need for permission check here. If user can view the Unit Group, they can view its units.
      resolve_units(**args)
    end

    # Similar to `Project.unit_types`, this supports displaying availability by unit types. Don't resolve in batch.
    def unit_types
      capacity = object.units.group(:unit_type_id).count
      unoccupied = object.units.unoccupied_on.group(:unit_type_id).count

      object.units.map(&:unit_type).uniq.compact.map do |unit_type|
        OpenStruct.new(
          id: "#{object.id}:#{unit_type.id}",
          unit_type: unit_type.description,
          capacity: capacity[unit_type.id] || 0,
          availability: unoccupied[unit_type.id] || 0,
        )
      end
    end

    def capacity
      object.units.count
    end

    def availability
      object.units.unoccupied_on.count
    end
  end
end
