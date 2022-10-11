###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# PerformanceMeasurement driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:performance_measurement)
#
# use with caution!
RailsDrivers.loaded << :performance_measurement

Rails.application.config.help_links << {
  controller_path: 'performance_measurement/warehouse_reports/reports',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/CoC-Performance-Measurement-Dashboard',
}

Rails.application.config.help_links << {
  controller_path: 'performance_measurement/warehouse_reports/reports',
  action_name: 'show',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/CoC-Performance-Measurement-Dashboard',
}

Rails.application.config.help_links << {
  controller_path: 'performance_measurement/warehouse_reports/reports',
  action_name: 'details',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/CoC-Performance-Measurement-Dashboard',
}

Rails.application.config.help_links << {
  controller_path: 'performance_measurement/warehouse_reports/goal_configs',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/CoC-Performance-Measurement-Dashboard',
}

Rails.application.config.help_links << {
  controller_path: 'performance_measurement/warehouse_reports/goal_configs',
  action_name: 'edit',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/CoC-Performance-Measurement-Dashboard',
}
