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
    class ClsBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      def initialize(enrollment:, date:, situation_code:, data_source:, user_id:)
        @enrollment      = enrollment
        @date            = date
        @situation_code  = situation_code
        @ds              = data_source
        @uid             = user_id
      end

      def build!
        Hmis::Hud::CurrentLivingSituation.create!(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @date.to_datetime,
          DateUpdated: @date.to_datetime,
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
