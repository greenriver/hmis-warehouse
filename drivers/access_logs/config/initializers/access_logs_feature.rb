# The core app (or other drivers) can check the presence of the
# AccessLogs driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:access_logs)
#
# use with caution!
RailsDrivers.loaded << :access_logs
