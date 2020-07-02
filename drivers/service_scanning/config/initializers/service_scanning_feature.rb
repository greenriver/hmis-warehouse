# The core app (or other drivers) can check the presence of the
# ServiceScanning driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:service_scanning)
#
# use with caution!
RailsDrivers.loaded << :service_scanning
