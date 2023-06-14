###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPostingInput < BaseInputObject
    argument :status_note, String, required: false
    argument :status, ID, required: false
    argument :denial_reason, ID, required: false
    argument :denial_note, String, required: false
    argument :referral_result, ID, required: false
    argument :re_request, Boolean, required: false

    def to_params
      # re_request is not a posting attribute. It's on the input because
      # we are have to include it in the form
      to_h.except(:re_request)
    end
  end
end
