###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# PublicReports driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:public_reports)
#
# use with caution!
RailsDrivers.loaded << :public_reports

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/point_in_time',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Point-in-Time-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/pit_by_month',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Point-in-Time-by-Month-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/number_housed',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Number-Housed-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/homeless_count',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Number-Homeless-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/homeless_count_comparison',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Percent-Homeless-Comparison-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/homeless_populations',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Homeless-Populations-Report-Generator',
}

Rails.application.config.help_links << {
  controller_path: 'public_reports/warehouse_reports/state_level_homelessness',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/State-Level-Homelessness-Report-Generator',
}
