# The core app (or other drivers) can check the presence of the
# Superset driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:superset)
#
# use with caution!
RailsDrivers.loaded << :superset
