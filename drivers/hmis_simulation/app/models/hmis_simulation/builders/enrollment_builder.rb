###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates Enrollment records for a household entering a project.
    # Always creates one enrollment for the HoH. For each household member,
    # rolls household_cohesion_probability to decide inclusion.
    #
    # Returns:
    #   {
    #     hoh_enrollment:    Hmis::Hud::Enrollment,
    #     member_enrollments: [Hmis::Hud::Enrollment],
    #   }
    class EnrollmentBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      # Project types that receive a MoveInDate on enrollment entry
      PH_PROJECT_TYPES = [3, 9, 10, 13].freeze

      # rng_seed: pre-computed integer seed for cohesion probability rolls.
      # Callers derive it as: simulation_seed + "entry:#{date}:#{client_id}".hash
      def initialize(
        project:,
        hud_household_id:,
        entry_date:,
        coc_code:,
        hoh_client:,
        member_relationships: [],
        household_cohesion_probability: 1.0,
        data_source:,
        user_id:,
        rng_seed:
      )
        @project       = project
        @household_id  = hud_household_id
        @entry_date    = entry_date
        @coc_code      = coc_code
        @hoh           = hoh_client
        @members       = member_relationships
        @cohesion_prob = household_cohesion_probability.to_f
        @ds            = data_source
        @uid           = user_id
        @rng_seed      = rng_seed
      end

      def build!
        hoh_enrollment = create_enrollment(@hoh, 1)

        member_enrollments = @members.each_with_index.filter_map do |member, idx|
          next unless include_member?(idx)

          client = Hmis::Hud::Client.find(member['hud_client_id'])
          create_enrollment(client, member['relationship_to_hoh'].to_i)
        end

        { hoh_enrollment: hoh_enrollment, member_enrollments: member_enrollments }
      end

      private

      def create_enrollment(client, relationship_to_hoh)
        Hmis::Hud::Enrollment.create!(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @entry_date.to_datetime,
          DateUpdated: @entry_date.to_datetime,
          EnrollmentID: FakeIdentifier.uuid,
          PersonalID: client.PersonalID,
          project_pk: @project.id,
          HouseholdID: @household_id,
          EntryDate: @entry_date,
          MoveInDate: (PH_PROJECT_TYPES.include?(@project.ProjectType) ? @entry_date : nil),
          RelationshipToHoH: relationship_to_hoh,
          DisablingCondition: 99,
          LivingSituation: 116,
          EnrollmentCoC: @coc_code,
        )
      end

      def include_member?(index)
        return true if @cohesion_prob >= 1.0
        return false if @cohesion_prob <= 0.0

        Random.new(@rng_seed + index).rand < @cohesion_prob
      end
    end
  end
end
