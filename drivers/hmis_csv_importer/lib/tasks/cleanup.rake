###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :cleanup do
  # rails driver:hmis_csv_importer:cleanup:expire_and_delete
  desc 'Clean importer & loader tables'
  task :expire_and_delete, [] => [:environment] do
    # Determine if we should expire any new data and delete it
    HmisCsvImporter::Cleanup::ExpireImportersAndLoadersJob.perform_now(dry_run: false)
  end

  # rails driver:hmis_csv_importer:cleanup:remove_expired_import_overrides
  desc 'Remove expired HMIS CSV import overrides'
  task remove_expired_import_overrides: [:environment, 'log:info_to_stdout'] do
    HmisCsvImporter::ImportOverride.remove_expired!
  end
end
