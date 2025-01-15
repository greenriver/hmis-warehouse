###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# MedicaidHmisInterchange driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:medicaid_hmis_interchange)
#
# use with caution!
RailsDrivers.loaded << :medicaid_hmis_interchange
