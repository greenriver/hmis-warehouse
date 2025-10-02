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
        exports = ::GrdaWarehouse::RecurringHmisExport.all.filter { |e| e.options['version'] == '2024' }

        exports.each do |export|
          updated_options = export.options.deep_dup
          updated_options['version'] = '2026'
          export.update!(options: updated_options)
        end

        send_single_notification("Updated #{exports.count} recurring HMIS exports from 2024 to 2026", 'UpgradeRecurringExports') if exports.any?
      end
    end
  end
end
