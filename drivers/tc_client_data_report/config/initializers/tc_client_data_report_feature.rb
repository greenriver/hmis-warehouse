# The core app (or other drivers) can check the presence of the
# TcClientDataReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:tc_client_data_report)
#
# use with caution!
RailsDrivers.loaded << :tc_client_data_report
