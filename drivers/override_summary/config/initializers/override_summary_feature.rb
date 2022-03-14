# The core app (or other drivers) can check the presence of the
# OverrideSummary driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:override_summary)
#
# use with caution!
RailsDrivers.loaded << :override_summary
