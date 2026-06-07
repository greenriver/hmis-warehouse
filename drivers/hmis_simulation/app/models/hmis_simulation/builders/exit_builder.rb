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
    class ExitBuilder < BaseBuilder
      def initialize(enrollment:, exit_date:, exit_destinations:, data_source:, user_id:, seed:, context_prefix:)
        super(data_source: data_source, user_id: user_id)
        @enrollment        = enrollment
        @exit_date         = exit_date
        @exit_destinations = exit_destinations
        @seed              = seed
        @prefix            = context_prefix
      end

      def build!
        destination = sample_destination

        Hmis::Hud::Exit.create!(
          **audit_attrs(@exit_date),
          ExitID: FakeIdentifier.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          ExitDate: @exit_date,
          Destination: destination,
          OtherDestination: ('Other_' if destination.to_s == '17'),
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
