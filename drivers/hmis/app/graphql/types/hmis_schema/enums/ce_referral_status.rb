###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeReferralStatus < Types::BaseEnum
    Hmis::Ce::Referral.state_machine_states.each { |name| value name, description: name.to_s.humanize }
  end
end
