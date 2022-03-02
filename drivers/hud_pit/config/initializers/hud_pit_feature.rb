# The core app (or other drivers) can check the presence of the
# HudPit driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_pit)
#
# use with caution!
RailsDrivers.loaded << :hud_pit

Rails.application.config.hud_reports['HudPit::Generators::Pit::Fy2022::Generator'] = {
  title: 'Point in Time Count',
  helper: 'hud_reports_pits_path',
}
