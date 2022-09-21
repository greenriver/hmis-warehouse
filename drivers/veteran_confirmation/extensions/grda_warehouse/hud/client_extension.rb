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

    included do
      has_many :va_check_histories, class_name: 'VeteranConfirmation::VaCheckHistory'
      has_one :recent_va_check, -> do
        merge(VeteranConfirmation::VaCheckHistory.recent)
      end, class_name: 'VeteranConfirmation::VaCheckHistory'
    end

    MIN_DAYS = 7.days

    def va_check_enabled?
      return false if veteran?
      return false if va_verified_veteran?
      return false unless VeteranConfirmation::Credential.exists?

      return recent_va_check&.check_date.nil? || recent_va_check.check_date <= Date.current - MIN_DAYS
    end

    def check_va_veteran_status(user: nil)
      checker = VeteranConfirmation::Checker.new
      query_results = checker.check(GrdaWarehouse::Hud::Client.where(id: id))
      result = query_results[id] == VeteranConfirmation::Checker::CONFIRMED
      update(va_verified_veteran: va_verified_veteran || result)
      va_check_histories.create(
        response: query_results[id],
        check_date: Date.current,
        user_id: user&.id,
      )
      adjust_veteran_status
    end
  end
end
