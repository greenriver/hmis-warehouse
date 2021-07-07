# The core app (or other drivers) can check the presence of the
# CasCeEvents driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:cas_ce_events)
#
# use with caution!
RailsDrivers.loaded << :cas_ce_events
