###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class SignatureRequests::PcpSignatureRequest < SignatureRequest
    def pcp_request?
      true
    end
    def aco_request?
      false
    end
    def patient_request?
      false
    end
  end
end