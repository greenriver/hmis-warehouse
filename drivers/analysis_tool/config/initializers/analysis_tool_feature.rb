# The core app (or other drivers) can check the presence of the
# AnalysisTool driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:analysis_tool)
#
# use with caution!
RailsDrivers.loaded << :analysis_tool
