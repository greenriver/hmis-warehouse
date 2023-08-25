###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPostingInput < BaseInputObject
    argument :status_note, String, required: false
    argument :status, ID, required: false
    argument :denial_reason, HmisSchema::Enums::ReferralPostingDenialReasonType, required: false
    argument :denial_note, String, required: false
    argument :referral_result, Types::HmisSchema::Enums::Hud::ReferralResult, required: false
    argument :resend_referral_request, Boolean, required: false

    def to_params
      # resend_referral_request is not a posting attribute. It's on the input because
      # we are have to include it in the form
      result = to_h.except(:resend_referral_request)
      result
    end
  end
end
