module Health
  class SignatureRequests::AcoSignatureRequest < SignatureRequest

    def self.expires_in
      if Rails.env.development?
        1.hours
      else
        3.days
      end
    end
  end
end