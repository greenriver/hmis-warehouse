###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisCsvImporter driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_importer)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_importer

# unless Rails.env.production?
#   Rails.application.config.queued_tasks[:initial_expiration_hmis_imports] = -> do
#     HmisCsvImporter::Cleanup::ExpireImportersAndLoadersJob.perform_later
#   end
# end
