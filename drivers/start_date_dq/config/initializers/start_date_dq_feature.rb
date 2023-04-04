###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# StartDateDq driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:start_date_dq)
#
# use with caution!
RailsDrivers.loaded << :start_date_dq
