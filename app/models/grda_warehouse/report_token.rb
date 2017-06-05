module GrdaWarehouse
  class ReportToken < GrdaWarehouseBase
    has_paper_trail

    validates :token, uniqueness: true
    before_validation :setup_token

    def expired?
      Time.now > expires_at
    end

    def setup_token
      self.token ||= SecureRandom.urlsafe_base64
      self.expires_at ||= Time.now + 1.year
    end
  end
end