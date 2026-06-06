###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates a single Hmis::Hud::Event record for a CE enrollment.
    #
    # CE events document referrals and housing placements. Three are generated
    # per lifecycle enrollment:
    #   1. Opening event (code 3 — CE Crisis Needs Assessment referral)
    #   2. Mid-enrollment event (code 4 — CE Housing Needs Assessment referral)
    #   3. Closing event (code matched to close reason)
    class EventBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      def initialize(
        enrollment:,
        date:,
        event_code:,
        data_source:,
        user_id:,
        referral_result: nil,
        result_date: nil
      )
        @enrollment      = enrollment
        @date            = date
        @event_code      = event_code
        @ds              = data_source
        @uid             = user_id
        @referral_result = referral_result
        @result_date     = result_date
      end

      def build!
        Hmis::Hud::Event.create!(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @date.to_datetime,
          DateUpdated: @date.to_datetime,
          EventID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          EventDate: @date,
          Event: @event_code,
          ReferralResult: @referral_result,
          ResultDate: @result_date,
        )
      end
    end
  end
end
