###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwenty driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_importer)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty

# Importers::HmisAutoDetect.add_importer('HmisCsvTwentyTwenty')
# Filters::HmisExport.register_version('HMIS 2020', '2020', 'HmisCsvTwentyTwenty::ExportJob')
