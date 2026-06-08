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
    # Populates HUD 3.917 Prior Living Situation fields (LivingSituation,
    # LengthOfStay, LOSUnderThreshold, PreviousStreetESSH, and conditionals),
    # DateOfEngagement (SO projects), and ReferralSource on all enrollments.
    #
    # Returns:
    #   {
    #     hoh_enrollment:     Hmis::Hud::Enrollment,
    #     member_enrollments: [Hmis::Hud::Enrollment],
    #   }
    class EnrollmentBuilder < BaseBuilder
      # PH project types — referenced by Engine#tick_housing_move_in
      PH_PROJECT_TYPES = [3, 9, 10, 13].freeze

      # LengthOfStay codes considered "under threshold" (less than one week)
      LOS_UNDER_THRESHOLD_CODES = [10, 11].freeze
      # LengthOfStay codes considered DK/prefer not/DNC — propagate to LOSUnderThreshold
      LOS_DK_CODES = [8, 9, 99].freeze

      # rng_seed: pre-computed integer seed for cohesion probability rolls.
      # Callers derive it as: simulation_seed + HmisSimulation::Hashing.stable_hash("entry:#{date}:#{client_id}")
      def initialize( # rubocop:disable Metrics/ParameterLists
        project:,
        hud_household_id:,
        entry_date:,
        coc_code:,
        hoh_client:,
        member_relationships: [],
        household_cohesion_probability: 1.0,
        population_config: {},
        data_source:,
        user_id:,
        rng_seed:
      )
        super(data_source: data_source, user_id: user_id)
        @project       = project
        @household_id  = hud_household_id
        @entry_date    = entry_date
        @coc_code      = coc_code
        @hoh           = hoh_client
        @members       = member_relationships
        @cohesion_prob = household_cohesion_probability.to_f
        @pop_cfg       = population_config || {}
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
        util    = HudHelper.util
        ls      = sample_length_of_stay(util)
        prev_ss = sample_previous_street_essh

        Hmis::Hud::Enrollment.create!(
          **audit_attrs(@entry_date),
          EnrollmentID: FakeIdentifier.uuid,
          PersonalID: client.PersonalID,
          project_pk: @project.id,
          ProjectID: @project.ProjectID,
          HouseholdID: @household_id,
          EntryDate: @entry_date,
          MoveInDate: nil,
          DateOfEngagement: (@project.ProjectType == 4 ? @entry_date + Random.new(@rng_seed + 6).rand(0..7) : nil),
          RelationshipToHoH: relationship_to_hoh,
          DisablingCondition: 99,
          EnrollmentCoC: @coc_code,
          LivingSituation: sample_living_situation(util),
          LengthOfStay: ls,
          LOSUnderThreshold: derive_los_under_threshold(ls),
          PreviousStreetESSH: prev_ss,
          DateToStreetESSH: (prev_ss == 1 ? sample_date_to_street_essh : nil),
          TimesHomelessPastThreeYears: (prev_ss == 1 ? sample_from_keys(util.times_homeless_options, rng_offset: 7) : nil),
          MonthsHomelessPastThreeYears: (prev_ss == 1 ? sample_from_keys(util.month_categories, rng_offset: 8) : nil),
          ReferralSource: sample_referral_source,
        )
      end

      def sample_living_situation(util)
        pls_cfg = @pop_cfg.dig('prior_living_situation', 'weights')
        if pls_cfg.present?
          Distribution.sample(
            { 'distribution' => 'weighted', 'weights' => pls_cfg.transform_values(&:to_f) },
            rng: Random.new(@rng_seed + 1),
          ).to_i
        else
          sample_from_keys(util.prior_living_situations, rng_offset: 1)
        end
      end

      def sample_length_of_stay(util)
        sample_from_keys(util.length_of_stays, rng_offset: 2)
      end

      def derive_los_under_threshold(los_code)
        return 1  if LOS_UNDER_THRESHOLD_CODES.include?(los_code)
        return 99 if LOS_DK_CODES.include?(los_code)

        0
      end

      def sample_previous_street_essh
        # ~40% yes (1), ~45% no (0), ~15% DNC (99)
        weights = { '1' => 0.40, '0' => 0.45, '99' => 0.15 }
        Distribution.sample(
          { 'distribution' => 'weighted', 'weights' => weights },
          rng: Random.new(@rng_seed + 3),
        ).to_i
      end

      def sample_date_to_street_essh
        days_ago = Random.new(@rng_seed + 4).rand(1..730)
        @entry_date - days_ago
      end

      def sample_referral_source
        # General weighted distribution; biased toward common codes
        weights = { '1' => 30, '2' => 10, '7' => 20, '11' => 15, '18' => 15, '39' => 10 }
        Distribution.sample(
          { 'distribution' => 'weighted', 'weights' => weights },
          rng: Random.new(@rng_seed + 5),
        ).to_i
      end

      def sample_from_keys(hash, rng_offset: 0)
        hash.keys.sample(random: Random.new(@rng_seed + rng_offset))
      end

      def include_member?(index)
        return true if @cohesion_prob >= 1.0
        return false if @cohesion_prob <= 0.0

        # Offset by 1000 to avoid seed collision with field-sampler offsets (0–6).
        Random.new(@rng_seed + 1000 + index).rand < @cohesion_prob
      end
    end
  end
end
