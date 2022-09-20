###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation::GrdaWarehouse
end

module VeteranConfirmation::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    MIN_DAYS = 7.days

    def va_check_enabled?
      return false if veteran?
      return false unless VeteranConfirmation::Credential.exists?

      return va_check_date.nil? || va_check_date <= Date.current - MIN_DAYS
    end

    def check_va_veteran_status
      checker = VeteranConfirmation::Checker.new
      query_results = checker.check(GrdaWarehouse::Hud::Client.where(id: id))
      result = query_results[id] == VeteranConfirmation::Checker::CONFIRMED
      update(veteran_override: veteran_override || result, va_check_date: Date.current)
      adjust_veteran_status
    end
  end
end
