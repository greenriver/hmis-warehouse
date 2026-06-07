###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates the Coordinated Entry (or other lifecycle-type) enrollment and
    # corresponding HmisSimulation::LifecycleEnrollment state record.
    #
    # Lifecycle enrollments are condition-triggered (not timed):
    #   - Opens when a client enters a trigger_population
    #   - EntryDate may be backdated by days_before_trigger
    #   - Closes on housing_move_in, disengagement timeout, or pre_entry_exit
    class LifecycleEnrollmentBuilder < BaseBuilder
      # HUD codes that are valid literally-homeless current living situations for CE entry.
      CE_LIVING_SITUATIONS = [116, 101, 118].freeze

      def initialize(client:, lifecycle_name:, ce_project:, opens_on:, coc_code:, data_source:, user_id:, rng_seed: nil)
        super(data_source: data_source, user_id: user_id)
        @client         = client
        @lifecycle_name = lifecycle_name
        @project        = ce_project
        @opens_on       = opens_on
        @coc_code       = coc_code
        @rng_seed       = rng_seed
      end

      def build!
        living_situation = if @rng_seed
          CE_LIVING_SITUATIONS.sample(random: Random.new(@rng_seed))
        else
          PLACE_NOT_MEANT_FOR_HABITATION
        end

        enrollment = Hmis::Hud::Enrollment.create!(
          **audit_attrs(@opens_on),
          EnrollmentID: FakeIdentifier.uuid,
          PersonalID: @client.PersonalID,
          project_pk: @project.id,
          ProjectID: @project.ProjectID,
          HouseholdID: FakeIdentifier.uuid,
          EntryDate: @opens_on,
          RelationshipToHoH: 1,
          DisablingCondition: 99,
          LivingSituation: living_situation,
          EnrollmentCoC: @coc_code,
        )

        LifecycleEnrollment.create!(
          data_source_id: @ds.id,
          hud_client_id: @client.id,
          hud_enrollment_id: enrollment.id,
          lifecycle_name: @lifecycle_name,
          status: 'open',
          opens_on: @opens_on,
        )
      end
    end
  end
end
