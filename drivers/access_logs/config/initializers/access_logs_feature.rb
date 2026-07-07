###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# AccessLogs driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:access_logs)
#
# use with caution!
RailsDrivers.loaded << :access_logs
