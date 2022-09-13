###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentyTwo driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_two)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_two

Rails.application.reloader.to_prepare do
  Filters::HmisExport.register_version('HMIS 2022', '2022', 'HmisCsvTwentyTwentyTwo::ExportJob')
end
Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentyTwo'
