###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :cleanup do
  # rails driver:hmis_csv_importer:cleanup:expire_and_delete
  desc 'Clean importer & loader tables'
  task :expire_and_delete, [] => [:environment] do
    # Determine if we should expire any new data
    HmisCsvImporter::Cleanup::ExpireImportersAndLoadersJob.perform_now(dry_run: true)
    # Enable for full mark and sweep
    # HmisCsvImporter::Cleanup::ExpireImportersAndLoadersJob.perform_now(dry_run: false)
  end
end
