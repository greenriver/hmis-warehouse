# The core app (or other drivers) can check the presence of the
# AccessControl driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:access_control)
#
# use with caution!
RailsDrivers.loaded << :access_control
