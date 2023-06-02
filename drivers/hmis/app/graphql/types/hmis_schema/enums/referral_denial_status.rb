###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReferralDenialStatus < Types::BaseEnum
    description 'Referral Denial Status'
    graphql_name 'ReferralDenialStatus'

    # FIXME
    value 'tbd', 'TBD'
  end
end
