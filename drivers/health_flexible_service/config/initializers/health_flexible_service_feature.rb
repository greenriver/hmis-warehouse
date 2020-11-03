# The core app (or other drivers) can check the presence of the
# HealthFlexibleService driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_flexible_service)
#
# use with caution!
RailsDrivers.loaded << :health_flexible_service
