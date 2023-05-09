###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# CePerformance driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ce_performance)
#
# use with caution!
RailsDrivers.loaded << :ce_performance
