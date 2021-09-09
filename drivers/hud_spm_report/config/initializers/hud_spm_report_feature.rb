###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HudSpmReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_spm_report)
#
# use with caution!
RailsDrivers.loaded << :hud_spm_report

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2020::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}

Rails.application.config.hud_reports['HudSpmReport::Generators::Fy2021::Generator'] = {
  title: 'System Performance Measures',
  helper: 'hud_reports_spms_path',
}
