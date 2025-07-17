###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwenty driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_importer)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty

Rails.application.config.hmis_data_lakes['2020'] = 'HmisCsvTwentyTwenty'
# Rails.application.reloader.to_prepare do
#   Importers::HmisAutoDetect.add_importer('HmisCsvTwentyTwenty')
#   Filters::HmisExport.register_version('HMIS 2020', '2020', 'HmisCsvTwentyTwenty::ExportJob')
# end
