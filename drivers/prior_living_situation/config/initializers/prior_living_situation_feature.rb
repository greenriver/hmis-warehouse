# The core app (or other drivers) can check the presence of the
# PriorLivingSituation driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:prior_living_situation)
#
# use with caution!
RailsDrivers.loaded << :prior_living_situation
