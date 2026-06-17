###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The core app (or other drivers) can check the presence of the
# SyntheticCeAssessment driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:synthetic_ce_assessment)
#
# use with caution!
RailsDrivers.loaded << :synthetic_ce_assessment

Rails.application.config.synthetic_assessment_types << 'SyntheticCeAssessment::EnrollmentCeAssessment'
