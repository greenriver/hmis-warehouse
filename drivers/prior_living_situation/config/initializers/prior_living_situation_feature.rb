###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# PriorLivingSituation driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:prior_living_situation)
#
# use with caution!
RailsDrivers.loaded << :prior_living_situation
