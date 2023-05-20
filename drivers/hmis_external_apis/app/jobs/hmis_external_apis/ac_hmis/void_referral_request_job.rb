###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Void a previously made referral request
# We should only call it if we have no Postings for this request
module HmisExternalApis::AcHmis
  class VoidReferralRequestJob < ApplicationJob
    include HmisExternalApis::AcHmis::ReferralJobMixin

    # @param referral_request [HmisExternalApis::AcHmis::ReferralRequest]
    # @param user [Hmis::User]
    def perform(referral_request:, user:)
      link.void_referral_request(referral_request_id: referral_request.identifier, requested_by: user.name)
      referral_request.update!(voided_by: user, voided_at: Time.now)
    end
  end
end
