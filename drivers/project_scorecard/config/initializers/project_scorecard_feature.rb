# The core app (or other drivers) can check the presence of the
# ProjectScorecard driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:project_scorecard)
#
# use with caution!
RailsDrivers.loaded << :project_scorecard
