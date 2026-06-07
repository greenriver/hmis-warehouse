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
    class EventBuilder < BaseBuilder
      def initialize(
        enrollment:,
        date:,
        event_code:,
        data_source:,
        user_id:,
        referral_result: nil,
        result_date: nil
      )
        super(data_source: data_source, user_id: user_id)
        @enrollment      = enrollment
        @date            = date
        @event_code      = event_code
        @referral_result = referral_result
        @result_date     = result_date
      end

      def build!
        Hmis::Hud::Event.create!(
          **audit_attrs(@date),
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
