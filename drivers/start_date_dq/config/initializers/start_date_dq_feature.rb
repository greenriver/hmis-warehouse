# The core app (or other drivers) can check the presence of the
# StartDateDq driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:start_date_dq)
#
# use with caution!
RailsDrivers.loaded << :start_date_dq
