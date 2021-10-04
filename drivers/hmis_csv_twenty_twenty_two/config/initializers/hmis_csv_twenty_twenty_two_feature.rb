# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentyTwo driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_two)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_two

Filters::HmisExport.register_version('HMIS 2022', '2022', 'HmisCsvTwentyTwentyTwo::ExportJob')
Rails.application.config.hmis_data_lake = 'HmisCsvTwentyTwentyTwo'
