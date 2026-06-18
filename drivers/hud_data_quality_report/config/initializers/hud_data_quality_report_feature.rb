###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# HudDataQualityReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_data_quality_report)
#
# use with caution!
RailsDrivers.loaded << :hud_data_quality_report
