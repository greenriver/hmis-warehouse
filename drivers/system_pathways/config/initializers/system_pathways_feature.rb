# The core app (or other drivers) can check the presence of the
# SystemPathways driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:system_pathways)
#
# use with caution!
RailsDrivers.loaded << :system_pathways
