###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HudDataQualityReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_data_quality_report)
#
# use with caution!
RailsDrivers.loaded << :hud_data_quality_report

Rails.application.config.hud_reports['HudDataQualityReport::Generators::Fy2020::Generator'] = {
  title: 'Data Quality Report',
  helper: 'hud_reports_dqs_path',
}

Rails.application.config.hud_reports['HudDataQualityReport::Generators::Fy2021::Generator'] = {
  title: 'Data Quality Report',
  helper: 'hud_reports_dqs_path',
}
