# The core app (or other drivers) can check the presence of the
# ZipCodeReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:zip_code_report)
#
# use with caution!
RailsDrivers.loaded << :zip_code_report
