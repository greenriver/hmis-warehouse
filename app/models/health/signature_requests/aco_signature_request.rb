###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class SignatureRequests::AcoSignatureRequest < SignatureRequest

    def self.expires_in
      if Rails.env.development?
        1.hours
      else
        3.days
      end
    end

    def pcp_request?
      false
    end
    def aco_request?
      true
    end
    def patient_request?
      false
    end
  end
end
