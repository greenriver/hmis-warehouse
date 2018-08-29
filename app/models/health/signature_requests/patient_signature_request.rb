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