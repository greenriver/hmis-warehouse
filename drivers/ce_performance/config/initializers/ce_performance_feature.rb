# The core app (or other drivers) can check the presence of the
# CePerformance driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ce_performance)
#
# use with caution!
RailsDrivers.loaded << :ce_performance
