###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# PerformanceMetrics driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:homeless_summary_report)
#
# use with caution!
RailsDrivers.loaded << :homeless_summary_report

Rails.application.config.help_links << {
  controller_path: 'homeless_summary_report/warehouse_reports/reports',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/System-Performance-Measures-by-Sub-Population',
}

Rails.application.config.help_links << {
  controller_path: 'homeless_summary_report/warehouse_reports/reports',
  action_name: 'show',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/System-Performance-Measures-by-Sub-Population',
}
