# The core app (or other drivers) can check the presence of the
# HudPathReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_path_report)
#
# use with caution!
RailsDrivers.loaded << :hud_path_report
