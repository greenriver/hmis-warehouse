# The core app (or other drivers) can check the presence of the
# Financial driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:financial)
#
# use with caution!
RailsDrivers.loaded << :financial
