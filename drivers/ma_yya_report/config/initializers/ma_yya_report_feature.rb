###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# MaYyaReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ma_yya_report)
#
# use with caution!
RailsDrivers.loaded << :ma_yya_report

# Rails.application.config.synthetic_youth_education_status_types << 'MaYyaReport::Synthetic::YouthEducationStatus'
