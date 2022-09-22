# The core app (or other drivers) can check the presence of the
# HudLsa driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_lsa)
#
# use with caution!
RailsDrivers.loaded << :hud_lsa

Rails.application.config.hud_reports['HudLsa::Generators::Fy2022::Lsa'] = {
  title: 'Longitudinal System Analysis',
  helper: 'hud_reports_lsas_path',
}
