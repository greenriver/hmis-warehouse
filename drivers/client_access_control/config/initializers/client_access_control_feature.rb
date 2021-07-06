# The core app (or other drivers) can check the presence of the
# ClientAccessControl driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:client_access_control)
#
# use with caution!
RailsDrivers.loaded << :client_access_control
