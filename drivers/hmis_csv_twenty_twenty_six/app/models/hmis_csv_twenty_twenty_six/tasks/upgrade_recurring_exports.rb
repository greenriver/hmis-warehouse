###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  module Tasks
    class UpgradeRecurringExports
      include NotifierConfig

      def self.upgrade!
        count = ::GrdaWarehouse::RecurringHmisExport.where(version: '2024').count
        ::GrdaWarehouse::RecurringHmisExport.where(version: '2024').update_all(version: '2026')

        send_single_notification("Updated #{count} recurring HMIS exports from 2024 to 2026", 'UpgradeRecurringExports') if count.positive?
      end
    end
  end
end
