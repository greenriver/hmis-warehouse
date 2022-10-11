###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ServiceScanning driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:core_demographics_report)
#
# use with caution!
RailsDrivers.loaded << :core_demographics_report

Rails.application.config.help_links << {
  controller_path: 'core_demographics_report/warehouse_reports/core',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Core-Demographics',
}
