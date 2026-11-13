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
      def initialize(enrollment:, date:, situation_code:, data_source:, user_id:, id_generator: FakeIdentifier)
        super(data_source: data_source, user_id: user_id, id_generator: id_generator)
        @enrollment      = enrollment
        @date            = date
        @situation_code  = situation_code
      end

      def build!
        Hmis::Hud::CurrentLivingSituation.create!(
          **audit_attrs(@date),
          CurrentLivingSitID: @id_gen.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          InformationDate: @date,
          CurrentLivingSituation: @situation_code,
        )
      end
    end
  end
end
