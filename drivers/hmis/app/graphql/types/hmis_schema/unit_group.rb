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
      # No need for permission check here. If user can view the Unit Group, they can view its units.
      resolve_units(**args)
    end
  end
end
