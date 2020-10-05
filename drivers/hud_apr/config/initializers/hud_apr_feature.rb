# The core app (or other drivers) can check the presence of the
# HudApr driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_apr)
#
# use with caution!
RailsDrivers.loaded << :hud_apr

Rails.application.config.hud_reports['HudApr::Generators::Apr::Fy2020::Generator'] = {
  title: 'Annual Performance Report',
  helper: 'hud_reports_aprs_path',
}

Rails.application.config.hud_reports['HudApr::Generators::Caper::Fy2020::Generator'] = {
  title: 'Consolidated Annual Performance and Evaluation Report',
  helper: 'hud_reports_capers_path',
}
