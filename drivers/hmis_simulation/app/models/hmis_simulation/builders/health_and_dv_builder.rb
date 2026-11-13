###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates one Hmis::Hud::HealthAndDv record at enrollment entry.
    class HealthAndDvBuilder < BaseBuilder
      # HUD GeneralHealthStatus values
      GENERAL_HEALTH = { 'excellent' => 1, 'good' => 2, 'fair' => 3, 'poor' => 4 }.freeze

      def initialize(enrollment:, date:, hdv_config:, data_source:, user_id:, rng_seed:, stage: :entry, id_generator: FakeIdentifier)
        super(data_source: data_source, user_id: user_id, id_generator: id_generator)
        @enrollment = enrollment
        @date       = date
        @cfg        = (hdv_config || {}).deep_stringify_keys
        @rng_seed   = rng_seed
        @stage      = stage
      end

      def build!
        dcs = DATA_COLLECTION_STAGES.fetch(@stage, 1)
        dv_survivor = roll_probability('dv_survivor_probability', 0)
        currently_fleeing = dv_survivor == 1 ? roll_probability('currently_fleeing_probability', 1) : 0
        health_status = sample_general_health

        Hmis::Hud::HealthAndDv.create!(
          **audit_attrs(@date),
          HealthAndDVID: @id_gen.uuid,
          EnrollmentID: @enrollment.EnrollmentID,
          PersonalID: @enrollment.PersonalID,
          InformationDate: @date,
          DataCollectionStage: dcs,
          DomesticViolenceSurvivor: dv_survivor,
          CurrentlyFleeing: currently_fleeing,
          GeneralHealthStatus: health_status,
        )
      end

      private

      def roll_probability(config_key, rng_offset)
        prob = @cfg[config_key].to_f
        Random.new(@rng_seed + rng_offset).rand < prob ? 1 : 0
      end

      def sample_general_health
        health_cfg = @cfg['general_health'] || { 'fair' => 1.0 }
        valid = health_cfg.slice(*GENERAL_HEALTH.keys).transform_values(&:to_f)
        return 3 if valid.values.sum.zero?

        cfg = { 'distribution' => 'weighted', 'weights' => valid }
        key = Distribution.sample(cfg, rng: Random.new(@rng_seed + 2))
        GENERAL_HEALTH[key] || 3
      end
    end
  end
end
