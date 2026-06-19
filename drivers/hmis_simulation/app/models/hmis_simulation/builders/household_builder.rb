###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates a household: one HoH Client plus any member Clients defined by the
    # household template. Also creates an HmisSimulation::HouseholdGroup record
    # that tracks composition for re-enrollment continuity.
    #
    # Returns a result hash consumed by the Engine and later by EnrollmentBuilder:
    #   {
    #     hoh_id:              bigint,   # Hmis::Hud::Client id for the HoH
    #     hud_household_id:    string,   # FAKE UUID used as HouseholdID in Enrollment records
    #     household_group_id:  bigint,   # HmisSimulation::HouseholdGroup id
    #     member_relationships: [        # empty for single-adult households
    #       { 'hud_client_id' => N, 'relationship_to_hoh' => N }
    #     ],
    #   }
    class HouseholdBuilder < BaseBuilder
      def initialize(
        household_template:,
        household_template_name:,
        data_quality_config:,
        data_source:,
        user_id:,
        date:,
        seed:,
        context_prefix:,
        id_generator: FakeIdentifier
      )
        super(data_source: data_source, user_id: user_id, id_generator: id_generator)
        @template      = (household_template || {}).deep_stringify_keys
        @template_name = household_template_name
        @dq            = (data_quality_config || {}).deep_stringify_keys
        @date          = date
        @seed          = seed
        @prefix        = context_prefix
      end

      def build!
        hud_household_id = @id_gen.uuid
        member_relationships = []

        # Build HoH
        hoh_result = build_client(@template['hoh'] || {}, "#{@prefix}:hoh")
        hoh_id     = hoh_result[:client].id

        # Build members
        (@template['members'] || []).each_with_index do |member_cfg, group_idx|
          count = member_count(member_cfg, group_idx)
          count.times do |member_idx|
            context = "#{@prefix}:member:#{group_idx}:#{member_idx}"
            member_result = build_client(member_client_config(member_cfg), context)
            member_relationships << {
              'hud_client_id' => member_result[:client].id,
              'relationship_to_hoh' => member_cfg['relationship'].to_i,
            }
          end
        end

        # Persist household group
        group = HmisSimulation::HouseholdGroup.create!(
          data_source_id: @ds.id,
          hoh_client_id: hoh_id,
          household_template_name: @template_name,
          member_relationships: member_relationships,
        )

        {
          hoh_id: hoh_id,
          hud_household_id: hud_household_id,
          household_group_id: group.id,
          member_relationships: member_relationships,
        }
      end

      private

      def build_client(client_config, context)
        ClientBuilder.new(
          client_config: client_config,
          data_quality_config: @dq,
          data_source: @ds,
          user_id: @uid,
          date: @date,
          seed: @seed,
          context_prefix: context,
          id_generator: @id_gen,
        ).build!
      end

      def member_count(member_cfg, group_idx)
        count_cfg = member_cfg['count']
        return 1 unless count_cfg.present?

        rng  = Random.new(@seed + HmisSimulation::Hashing.stable_hash("#{@prefix}:member_count:#{group_idx}"))
        raw  = Distribution.sample(count_cfg.deep_stringify_keys, rng: rng)
        min  = count_cfg['min'].to_i
        raw  = [raw.round, min].max if min.positive?
        max  = count_cfg['max']
        raw  = [raw, max.to_i].min if max.present?
        raw.to_i.clamp(1, 10)
      end

      def member_client_config(member_cfg)
        {
          'age' => member_cfg['age'],
          'gender' => nil,
          'veteran_probability' => 0.0,
          'race' => nil,
        }
      end
    end
  end
end
