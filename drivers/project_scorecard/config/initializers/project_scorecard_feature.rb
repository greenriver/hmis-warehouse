###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ProjectScorecard driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:project_scorecard)
#
# use with caution!
RailsDrivers.loaded << :project_scorecard
