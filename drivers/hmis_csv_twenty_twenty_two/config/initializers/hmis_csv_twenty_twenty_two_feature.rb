###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwentyTwo driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_twenty_twenty_two)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty_two

Rails.application.config.hmis_data_lakes['2022'] = 'HmisCsvTwentyTwentyTwo'
# Rails.application.reloader.to_prepare do
#   Filters::HmisExport.register_version('HMIS 2022', '2022', 'HmisCsvTwentyTwentyTwo::ExportJob')
# end
