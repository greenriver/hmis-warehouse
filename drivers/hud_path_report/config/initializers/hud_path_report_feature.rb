###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HudPathReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_path_report)
#
# use with caution!
RailsDrivers.loaded << :hud_path_report

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2020::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}

Rails.application.config.hud_reports['HudPathReport::Generators::Fy2021::Generator'] = {
  title: 'Annual PATH Report',
  helper: 'hud_reports_paths_path',
}
