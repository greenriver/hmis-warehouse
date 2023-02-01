# The core app (or other drivers) can check the presence of the
# MaReports driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ma_reports)
#
# use with caution!
RailsDrivers.loaded << :ma_reports
