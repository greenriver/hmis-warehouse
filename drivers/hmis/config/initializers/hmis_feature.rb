# The core app (or other drivers) can check the presence of the
# Hmis driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis)
#
# use with caution!
RailsDrivers.loaded << :hmis
