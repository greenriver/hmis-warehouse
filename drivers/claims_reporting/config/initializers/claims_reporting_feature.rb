###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# ClaimsReporting driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:claims_reporting)
#
# use with caution!
RailsDrivers.loaded << :claims_reporting
