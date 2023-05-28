###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReferralPostingStatus < Types::BaseEnum
    description 'Referral Posting Status'
    graphql_name 'ReferralPostingStatus'

    HmisExternalApis::AcHmis::ReferralPosting.statuses.each_pair do |field, field_value|
      value field, value: field_value
    end
  end
end
