# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::Enums::CeOpportunityStatus < Types::BaseEnum
    Hmis::Ce::Opportunity.state_machine_states.each { |state| value state.name }
  end
end
