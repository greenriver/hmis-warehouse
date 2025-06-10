###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentySix driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_six)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_six

Rails.application.reloader.to_prepare do
  Filters::HmisExport.register_version('HMIS 2026', '2026', 'HmisCsvTwentyTwentySix::ExportJob')
end

Rails.application.config.hmis_data_lakes['2026'] = 'HmisCsvTwentyTwentySix'

if (Date.current >= '2025-10-01'.to_date && Rails.env.production?) || (Date.current >= '2025-09-01'.to_date && Rails.env.staging?)
  Rails.application.config.queued_tasks[:hmis_twenty_twenty_six_upgrade_recurring_exports] = -> do
    HmisCsvTwentyTwentySix::Tasks::UpgradeRecurringExports.upgrade!
  end
end
