###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# ZipCodeReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:zip_code_report)
#
# use with caution!
RailsDrivers.loaded << :zip_code_report
