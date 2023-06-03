###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::Enums::ReferralPostingStatus < Types::BaseEnum
    description 'Referral Posting Status'
    graphql_name 'ReferralPostingStatus'

    HmisExternalApis::AcHmis::ReferralPosting.statuses.each_key do |field|
      value field, field.gsub(/_status\z/, '').humanize
    end
  end
end
