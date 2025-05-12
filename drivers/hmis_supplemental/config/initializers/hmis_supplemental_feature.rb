###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HmisSupplemental driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_supplemental)
#
# use with caution!
RailsDrivers.loaded << :hmis_supplemental
