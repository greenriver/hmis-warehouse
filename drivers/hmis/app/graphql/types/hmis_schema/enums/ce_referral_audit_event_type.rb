###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeReferralAuditEventType < Types::BaseEnum
    graphql_name 'CeReferralAuditEventType'

    value 'START_REFERRAL', description: 'Started Referral'
    value 'COMPLETE_STEP', description: 'Completed Task'
    value 'ACCEPT_REFERRAL', description: 'Accepted Referral'
    value 'REJECT_REFERRAL', description: 'Declined Referral'
  end
end
