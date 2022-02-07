###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class ReportToken < GrdaWarehouseBase
    has_paper_trail

    validates :token, uniqueness: true
    before_validation :setup_token

    def expired?
      Time.now > expires_at
    end

    def valid_for_report?(report_id)
      ! expired? && report_id == report_id
    end

    def setup_token
      self.token ||= SecureRandom.urlsafe_base64
      self.expires_at ||= Time.now + 1.year
    end
  end
end
