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
    field :utilization, Float, null: true, description: 'Percentage of units in this group that are currently occupied'
    units_field

    # CE fields
    field :eligibility_requirements, [HmisSchema::CeMatchRule], null: true
    field :priority_scheme, HmisSchema::CeMatchRule, null: true
    field :workflow_template_identifier, String, null: true
    field :workflow_template_name, String, null: true
    # TODO(#7538) resolve default contacts for workflow template

    def workflow_template_name
      object.workflow_template&.name
    end

    def units(**args)
      return Hmis::Unit.none unless current_permission?(entity: object.project, permission: :can_view_units)

      resolve_units(**args)
    end

    def capacity
      object.units.count
    end

    def availability
      object.units.unoccupied_on.count
    end

    def utilization
      return nil if capacity.zero?

      ((capacity - availability).to_f / capacity * 100).round(2)
    end
  end
end
