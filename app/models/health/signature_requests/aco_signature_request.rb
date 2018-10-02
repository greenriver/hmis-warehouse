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