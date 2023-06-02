###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPostingInput < BaseInputObject
    argument :status_note, String, required: false
    argument :posting_status_id, HmisSchema::Enums::ReferralPostingStatus, required: false
    argument :denial_reason, HmisSchema::Enums::ReferralPostingStatus, required: false
    argument :denial_reason_id, HmisSchema::Enums::ReferralPostingStatus, required: false

    def to_params
      to_h
    end
  end
end
