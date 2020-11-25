# The core app (or other drivers) can check the presence of the
# ProjectPassFail driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:project_pass_fail)
#
# use with caution!
RailsDrivers.loaded << :project_pass_fail
