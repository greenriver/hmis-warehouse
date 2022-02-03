###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# PerformanceMeasurement driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:performance_measurement)
#
# use with caution!
RailsDrivers.loaded << :performance_measurement
