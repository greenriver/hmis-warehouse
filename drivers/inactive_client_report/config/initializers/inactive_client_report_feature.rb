# The core app (or other drivers) can check the presence of the
# InactiveClientReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:inactive_client_report)
#
# use with caution!
RailsDrivers.loaded << :inactive_client_report
