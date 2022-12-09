# The core app (or other drivers) can check the presence of the
# CasAccess driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:cas_access)
#
# use with caution!
RailsDrivers.loaded << :cas_access
