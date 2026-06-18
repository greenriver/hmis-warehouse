###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentyFour
  module Tasks
    class UpgradeRecurringExports
      include NotifierConfig

      def self.upgrade!
        count = ::GrdaWarehouse::RecurringHmisExport.where(version: '2022').count
        ::GrdaWarehouse::RecurringHmisExport.where(version: '2022').update_all(version: '2024')

        send_single_notification("Updated #{count} recurring HMIS exports from 2022 to 2024", 'UpgradeRecurringExports') if count.positive?
      end
    end
  end
end
