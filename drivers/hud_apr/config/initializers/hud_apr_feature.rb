# The core app (or other drivers) can check the presence of the
# HudApr driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_apr)
#
# use with caution!
RailsDrivers.loaded << :hud_apr

Rails.application.config.hud_reports << ['Annual Performance Report', 'hud_reports_aprs_path']
