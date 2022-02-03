###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class SignatureRequests::PatientSignatureRequest < SignatureRequest

    def self.expires_in
      1.hours
    end

    def pcp_request?
      false
    end
    def aco_request?
      false
    end
    def patient_request?
      true
    end
  end
end
