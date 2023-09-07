###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentyFour driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_two)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_four

Rails.application.reloader.to_prepare do
  Filters::HmisExport.register_version('HMIS 2024', '2024', 'HmisCsvTwentyTwentyFour::ExportJob')
end
# TODO: enable when the importer is available
# Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentyFour'
