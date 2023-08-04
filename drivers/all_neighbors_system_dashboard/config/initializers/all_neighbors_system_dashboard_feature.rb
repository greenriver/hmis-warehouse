# The core app (or other drivers) can check the presence of the
# AllNeighborsSystemDashboard driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:all_neighbors_system_dashboard)
#
# use with caution!
RailsDrivers.loaded << :all_neighbors_system_dashboard
