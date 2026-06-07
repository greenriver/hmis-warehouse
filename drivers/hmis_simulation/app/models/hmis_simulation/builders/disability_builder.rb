###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates Hmis::Hud::Disability records at enrollment entry.
    # One record per disability type configured in disability_config.types.
    #
    # Returns { disabling_condition: 0|1 } so the caller can update the
    # enrollment's DisablingCondition field.
    class DisabilityBuilder < BaseBuilder
      # Config key → HUD DisabilityType integer
      TYPE_MAP = {
        'physical' => 5,
        'developmental' => 6,
        'chronic_health' => 7,
        'hiv_aids' => 8,
        'mental_health' => 9,
        'substance_use' => 10,
      }.freeze

      # Types for which IndefiniteAndImpairs is not applicable (HUD spec)
      NO_INDEFINITE_TYPES = [6, 8].freeze

      def initialize(enrollment:, date:, disability_config:, data_source:, user_id:, rng_seed:)
        super(data_source: data_source, user_id: user_id)
        @enrollment   = enrollment
        @date         = date
        @cfg          = (disability_config || {}).deep_stringify_keys
        @rng_seed     = rng_seed
      end

      def build!
        disabling_condition = roll_disabling_condition
        types = @cfg['types'] || {}
        always_disabling = false

        types.each_with_index do |(config_key, probability), idx|
          hud_type = TYPE_MAP[config_key]
          next unless hud_type

          rng = Random.new(@rng_seed + idx)
          response = rng.rand < probability.to_f ? 1 : 0
          indefinite = indefinite_and_impairs(hud_type, disabling_condition, idx)

          # Types 6 and 8 always qualify as disabling when present, regardless of the roll.
          always_disabling = true if response == 1 && NO_INDEFINITE_TYPES.include?(hud_type)

          Hmis::Hud::Disability.create!(
            **audit_attrs(@date),
            DisabilitiesID: FakeIdentifier.uuid,
            EnrollmentID: @enrollment.EnrollmentID,
            PersonalID: @enrollment.PersonalID,
            InformationDate: @date,
            DisabilityType: hud_type,
            DisabilityResponse: response,
            IndefiniteAndImpairs: indefinite,
            DataCollectionStage: 1,
          )
        end

        disabling_condition = true if always_disabling
        { disabling_condition: disabling_condition ? 1 : 0 }
      end

      private

      def roll_disabling_condition
        prob = @cfg['disabling_condition_probability'].to_f
        Random.new(@rng_seed + 999).rand < prob
      end

      def indefinite_and_impairs(hud_type, disabling_condition, idx)
        return nil if NO_INDEFINITE_TYPES.include?(hud_type)

        disabling_condition ? [0, 1].sample(random: Random.new(@rng_seed + idx + 100)) : 0
      end
    end
  end
end
