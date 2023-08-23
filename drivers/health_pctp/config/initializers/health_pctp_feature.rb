# The core app (or other drivers) can check the presence of the
# HealthPctp driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_pctp)
#
# use with caution!
RailsDrivers.loaded << :health_pctp
