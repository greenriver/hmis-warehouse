###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# DisabilitySummary driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:disability_summary)
#
# use with caution!
RailsDrivers.loaded << :disability_summary
