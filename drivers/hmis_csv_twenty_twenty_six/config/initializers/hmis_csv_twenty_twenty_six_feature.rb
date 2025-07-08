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

  # Generate custom models used for import.  It only runs at boot time, reading any YAML available.
  # New custom files need:
  # 1. A YAML file in drivers/hmis_csv_twenty_twenty_six/config/custom/ describing the CSV
  # 2. To run HmisCsvTwentyTwentySix::CustomFileManager.generate_custom_migrations! to create the migrations
  begin
    custom_files = HmisCsvTwentyTwentySix.custom_files_config['custom_files']
    if custom_files.any?
      Rails.logger.info "Generating FY2026 custom models at boot time for #{custom_files.count} files: #{custom_files.map { |f| f['class_name'] }.join(', ')}"
      HmisCsvTwentyTwentySix::CustomFileManager.generate_custom_models!
      Rails.logger.info 'Successfully generated FY2026 custom models'
    else
      Rails.logger.debug 'No custom files configured for FY2026'
    end
  rescue StandardError => e
    Rails.logger.error "Failed to generate FY2026 custom models at boot time: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end

Rails.application.config.hmis_data_lakes['2026'] = 'HmisCsvTwentyTwentySix'
Rails.application.config.hmis_importers['2026'] = 'HmisCsvTwentyTwentySix::Importer::Importer'
Rails.application.config.hmis_loaders['2026'] = 'HmisCsvTwentyTwentySix::Loader::Loader'

if (Date.current >= '2025-10-01'.to_date && Rails.env.production?) || (Date.current >= '2025-09-01'.to_date && Rails.env.staging?)
  Rails.application.config.queued_tasks[:hmis_twenty_twenty_six_upgrade_recurring_exports] = -> do
    HmisCsvTwentyTwentySix::Tasks::UpgradeRecurringExports.upgrade!
  end
end
