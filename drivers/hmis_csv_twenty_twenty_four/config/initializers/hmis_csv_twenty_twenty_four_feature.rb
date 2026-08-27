###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  Filters::HmisExport.register_version('HMIS 2024', '2024', 'HmisCsvTwentyTwentyFour::ExportJob')
end

Rails.application.config.hmis_data_lakes['2024'] = 'HmisCsvTwentyTwentyFour'

Rails.application.config.queued_tasks[:hmis_twenty_twenty_four_upgrade_recurring_exports] = -> do
  HmisCsvTwentyTwentyFour::Tasks::UpgradeRecurringExports.upgrade!
end
