# The core app (or other drivers) can check the presence of the
# EccoviaData driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:eccovia_data)
#
# use with caution!
RailsDrivers.loaded << :eccovia_data
