###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

Rails.application.config.hmis_data_lakes['2024'] = 'HmisCsvTwentyTwentyFour'
Rails.application.config.hmis_importers['2024'] = 'HmisCsvImporter::Importer::Importer'
Rails.application.config.hmis_loaders['2024'] = 'HmisCsvImporter::Loader::Loader'

Rails.application.config.queued_tasks[:hmis_twenty_twenty_four_upgrade_recurring_exports] = -> do
  HmisCsvTwentyTwentyFour::Tasks::UpgradeRecurringExports.upgrade!
end
