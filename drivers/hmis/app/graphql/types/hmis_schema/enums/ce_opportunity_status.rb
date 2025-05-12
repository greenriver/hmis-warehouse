###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeOpportunityStatus < Types::BaseEnum
    Hmis::Ce::Opportunity.state_machine_states.each { |state| value state.name, description: state.name.to_s.humanize }
  end
end
