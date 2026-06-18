###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# DestinationReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:destination_report)
#
# use with caution!
RailsDrivers.loaded << :user_permission_report
