###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentyFour driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_four)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_four

Rails.application.reloader.to_prepare do
  Filters::HmisExport.register_version('HMIS 2024', '2024', 'HmisCsvTwentyTwentyFour::ExportJob')
end

# Reminder: Disable any old versions when moving to 2026
Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentyFour'

Rails.application.config.queued_tasks[:hmis_twenty_twenty_four_upgrade_recurring_exports] = -> do
  HmisCsvTwentyTwentyFour::Tasks::UpgradeRecurringExports.upgrade!
end
