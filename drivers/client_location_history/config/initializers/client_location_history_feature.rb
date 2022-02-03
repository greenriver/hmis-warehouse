###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ClientLocationHistory driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:client_location_history)
#
# use with caution!
RailsDrivers.loaded << :client_location_history
