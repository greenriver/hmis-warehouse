###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchRuleApplicabilityConfigInput < BaseInputObject
    argument :project_types, [Types::HmisSchema::Enums::ProjectType], required: false
    argument :project_funders, [Types::HmisSchema::Enums::Hud::FundingSource], required: false

    def to_params
      to_h.compact
    end
  end
end
