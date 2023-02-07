# The core app (or other drivers) can check the presence of the
# EtlViewMaintainer driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:etl_view_maintainer)
#
# use with caution!
RailsDrivers.loaded << :etl_view_maintainer
