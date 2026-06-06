###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates an Exit record for a single Enrollment.
    # Samples the Destination field from the weighted exit_destinations map.
    class ExitBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      def initialize(enrollment:, exit_date:, exit_destinations:, data_source:, user_id:, seed:, context_prefix:)
        @enrollment        = enrollment
        @exit_date         = exit_date
        @exit_destinations = exit_destinations
        @ds                = data_source
        @uid               = user_id
        @seed              = seed
        @prefix            = context_prefix
      end

      def build!
        destination = sample_destination

        Hmis::Hud::Exit.create!(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @exit_date.to_datetime,
          DateUpdated: @exit_date.to_datetime,
          ExitID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          ExitDate: @exit_date,
          Destination: destination,
        )
      end

      private

      def sample_destination
        dests = @exit_destinations.transform_keys(&:to_s)
        cfg   = { 'distribution' => 'weighted', 'weights' => dests }
        rng   = Random.new(@seed + HmisSimulation::Hashing.stable_hash("#{@prefix}:destination"))
        Distribution.sample(cfg, rng: rng)
      end
    end
  end
end
