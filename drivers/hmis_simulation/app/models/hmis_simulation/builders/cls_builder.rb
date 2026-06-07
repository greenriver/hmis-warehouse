###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates one Hmis::Hud::CurrentLivingSituation record.
    # Called at enrollment entry for street/shelter populations, and
    # periodically for ongoing enrollments (future enhancement).
    class ClsBuilder < BaseBuilder
      def initialize(enrollment:, date:, situation_code:, data_source:, user_id:)
        super(data_source: data_source, user_id: user_id)
        @enrollment      = enrollment
        @date            = date
        @situation_code  = situation_code
      end

      def build!
        Hmis::Hud::CurrentLivingSituation.create!(
          **audit_attrs(@date),
          CurrentLivingSitID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          InformationDate: @date,
          CurrentLivingSituation: @situation_code,
        )
      end
    end
  end
end
