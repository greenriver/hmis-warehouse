# The core app (or other drivers) can check the presence of the
# DatalabTestkit driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:datalab_testkit)
#
# use with caution!
RailsDrivers.loaded << :datalab_testkit
