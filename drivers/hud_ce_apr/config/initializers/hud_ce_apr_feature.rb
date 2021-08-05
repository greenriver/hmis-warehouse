# The core app (or other drivers) can check the presence of the
# HudCeApr driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_ce_apr)
#
# use with caution!
RailsDrivers.loaded << :hud_ce_apr
