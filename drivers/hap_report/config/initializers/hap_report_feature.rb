###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HapReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hap_report)
#
# use with caution!
RailsDrivers.loaded << :hap_report
