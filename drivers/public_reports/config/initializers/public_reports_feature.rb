###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

Rails.application.config.to_prepare do
  [
    {
      controller_path: 'public_reports/warehouse_reports/point_in_time',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Point-in-Time-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/pit_by_month',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Point-in-Time-by-Month-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/number_housed',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Number-Housed-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/homeless_count',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Number-Homeless-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/homeless_count_comparison',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Percent-Homeless-Comparison-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/homeless_populations',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/Homeless-Populations-Report-Generator",
    },
    {
      controller_path: 'public_reports/warehouse_reports/state_level_homelessness',
      action_name: 'index',
      external_url: "#{GrdaWarehouse::Help::DEFAULT_HELP_URL}/State-Level-Homelessness-Report-Generator",
    },
  ].each do |report|
    Rails.application.config.help_links << report
  end
end
