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
    field :unit_types, [Types::HmisSchema::UnitTypeCapacity], null: false # TODO(#8157) - Unit Group should have exactly 1 Unit Type
    units_field
    field :unit_type, HmisSchema::UnitTypeObject, null: true

    # CE fields
    field :eligibility_requirements, [HmisSchema::CeMatchRule], null: true
    field :priority_scheme, HmisSchema::CeMatchRule, null: true, deprecation_reason: 'Replaced by prioritySchemes'
    field :priority_schemes, [HmisSchema::CeMatchRule], null: true
    field :workflow_template_identifier, String, null: true
    field :workflow_template_name, String, null: true
    field :direct_referral_workflow_template_identifier, String, null: true
    field :direct_referral_workflow_template_name, String, null: true
    field :ce_event_type, HmisSchema::Enums::Hud::EventType, null: true
    # TODO(#7538) resolve default contacts for workflow template

    def unit_type
      load_ar_association(object, :unit_type)
    end

    def priority_schemes
      Hmis::Ce::Match::Rule.priority_schemes_for_entity(object)
    end

    # TODO(#7957) - remove after deprecation period
    def priority_scheme
      priority_schemes&.first
    end

    def eligibility_requirements
      Hmis::Ce::Match::Rule.eligibility_requirements_for_entity(object)
    end

    def workflow_template_name
      object.workflow_template&.name
    end

    def direct_referral_workflow_template_name
      object.direct_referral_workflow_template&.name
    end

    def units(**args)
      # No need for permission check here. If user can view the Unit Group, they can view its units.
      resolve_units(**args)
    end

    # Similar to `Project.unit_types`, this supports displaying availability by unit types. Don't resolve in batch.
    def unit_types
      # Use preloaded units and active_unit_occupancies to avoid N+1 queries
      units = object.units.to_a
      occupied_unit_ids = units.flat_map { |unit| unit.active_unit_occupancies.map(&:unit_id) }.to_set

      capacity_by_type = Hash.new(0)
      availability_by_type = Hash.new(0)
      unit_types_map = {}

      units.each do |unit|
        next unless unit.unit_type

        unit_types_map[unit.unit_type.id] = unit.unit_type
        capacity_by_type[unit.unit_type.id] += 1
        availability_by_type[unit.unit_type.id] += 1 unless occupied_unit_ids.include?(unit.id)
      end

      unit_types_map.values.map do |unit_type|
        OpenStruct.new(
          id: "#{object.id}:#{unit_type.id}",
          unit_type: unit_type.description,
          capacity: capacity_by_type[unit_type.id],
          availability: availability_by_type[unit_type.id],
        )
      end
    end

    def capacity
      # Use preloaded units to avoid N+1 query
      object.units.size
    end

    def availability
      # Use preloaded units and active_unit_occupancies to avoid N+1 query
      units = object.units.to_a
      return 0 if units.empty?

      occupied_unit_ids = units.flat_map { |unit| unit.active_unit_occupancies.map(&:unit_id) }.to_set
      units.count { |unit| !occupied_unit_ids.include?(unit.id) }
    end
  end
end
