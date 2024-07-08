###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :cleanup do
  # rails driver:hmis_csv_importer:cleanup:expire_and_delete
  desc 'One time task to set Enrollment.project_pk'
  task :expire_and_delete, [] => [:environment] do
    # Remove any we expired previously
    # HmisCsvImporter::Cleanup::ExpireImportersJob.DeleteExpiredJob.perform_now

    # Determine if we should expire any new data
    HmisCsvImporter::Cleanup::ExpireImportersAndLoadersJob.perform_now
  end
end
