###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Reminders
    TOPICS = [
      ANNUAL_ASSESSMENT_TOPIC = 'annual_assessment'.freeze,
      AGED_INTO_ADULTHOOD_TOPIC = 'aged_into_adulthood'.freeze,
      INTAKE_INCOMPLETE_TOPIC = 'intake_incomplete'.freeze,
      EXIT_INCOMPLETE_TOPIC = 'exit_incomplete'.freeze,
      CURRENT_LIVING_SITUATION_TOPIC = 'current_living_situation'.freeze,
    ].freeze
  end
end
