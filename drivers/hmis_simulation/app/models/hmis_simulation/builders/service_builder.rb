###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates Hmis::Hud::Service records.
    # Currently supports bed nights (RecordType/TypeProvided 200) for ES NBN projects.
    # Future record types (referrals, PATH services, etc.) can be added as additional
    # build_* methods following the same pattern.
    class ServiceBuilder < BaseBuilder
      BED_NIGHT = 200

      def initialize(enrollment:, date:, data_source:, user_id:)
        super(data_source: data_source, user_id: user_id)
        @enrollment = enrollment
        @date       = date
      end

      def build_bed_night!
        Hmis::Hud::Service.create!(
          **audit_attrs(@date),
          ServicesID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          DateProvided: @date,
          RecordType: BED_NIGHT,
          TypeProvided: BED_NIGHT,
        )
      end
    end
  end
end
