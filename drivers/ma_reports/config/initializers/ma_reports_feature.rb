###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# MaReports driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ma_reports)
#
# use with caution!
RailsDrivers.loaded << :ma_reports
