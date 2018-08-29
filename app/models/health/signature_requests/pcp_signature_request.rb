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