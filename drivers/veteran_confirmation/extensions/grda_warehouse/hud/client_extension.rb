###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
        merge(VeteranConfirmation::VaCheckHistory.most_recent_first.limit(1))
      end, class_name: 'VeteranConfirmation::VaCheckHistory'
    end

    MIN_DAYS = 7.days

    def va_check_enabled?
      return false if veteran?
      return false if va_verified_veteran?
      return false unless VeteranConfirmation::Credential.exists?

      return recent_va_check.nil? || recent_va_check.occured_within(MIN_DAYS)
    end

    def check_va_veteran_status(user: nil)
      va_check_histories.new(user_id: user&.id).check
    end
  end
end
