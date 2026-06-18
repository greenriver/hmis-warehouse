###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ReferralPostingStatus < Types::BaseEnum
    description 'Referral Posting Status'
    graphql_name 'ReferralPostingStatus'

    HmisExternalApis::AcHmis::ReferralPosting.statuses.each_key do |field|
      value field, field.gsub(/_status\z/, '').humanize.titleize
    end
  end
end
