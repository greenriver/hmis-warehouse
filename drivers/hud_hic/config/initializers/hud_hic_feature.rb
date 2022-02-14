# The core app (or other drivers) can check the presence of the
# HudHic driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_hic)
#
# use with caution!
RailsDrivers.loaded << :hud_hic

Rails.application.config.hud_reports['HudHic::Generators::Hic::Fy2021::Generator'] = {
  title: 'Housing Inventory Count',
  helper: 'hud_reports_hics_path',
}
