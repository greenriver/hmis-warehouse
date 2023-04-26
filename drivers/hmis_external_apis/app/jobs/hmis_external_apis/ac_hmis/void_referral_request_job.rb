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
    # @param voided_by [Hmis::User]
    # @param url [String]
    def perform(referral_request:, voided_by:, url:)
      payload = {
        posting_id: referral_request.identifier,
      }
      post_referral_request(url, payload)
      # FIXME probably should look at response?
      referral_request.update!(voided_by: voided_by, voided_at: Time.now)
    end
  end
end
