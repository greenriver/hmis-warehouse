###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates a single Hmis::Hud::Client record plus a linked
    # Hmis::Hud::CustomClientName (primary: true).
    #
    # All identifiers use FakeIdentifier conventions:
    #   - PersonalID:  FAKE-prefixed 32-char UUID
    #   - SSN:         999-prefixed 9-digit string
    #   - FirstName:   US city name + "_"
    #   - LastName:    River/water body name + "_"
    #
    # Data quality rates are applied probabilistically from data_quality_config.
    # Randomness is deterministic — identical seed + context_prefix always
    # produces the same client attributes.
    #
    # Usage:
    #   result = HmisSimulation::Builders::ClientBuilder.new(
    #     client_config: hoh_config,
    #     data_quality_config: config['data_quality'],
    #     data_source: data_source,
    #     user_id: user_id,
    #     date: date,
    #     seed: seed,
    #     context_prefix: "spawn:#{date}:#{i}:hoh",
    #   ).build!
    #   # => { client: Hmis::Hud::Client, custom_name: Hmis::Hud::CustomClientName }
    class ClientBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      # Gender config key → HUD column name mapping
      GENDER_MAP = {
        'woman' => :Woman,
        'man' => :Man,
        'non_binary' => :NonBinary,
        'transgender' => :Transgender,
        'culturally_specific' => :CulturallySpecific,
        'different_identity' => :DifferentIdentity,
        'questioning' => :Questioning,
      }.freeze

      # Race config key → HUD column name mapping
      RACE_MAP = {
        'white' => :White,
        'black_af_american' => :BlackAfAmerican,
        'hispanic_latinaeo' => :HispanicLatinaeo,
        'am_ind_ak_native' => :AmIndAKNative,
        'asian' => :Asian,
        'native_hi_pacific' => :NativeHIPacific,
        'mid_east_n_african' => :MidEastNAfrican,
      }.freeze

      def initialize(client_config:, data_quality_config:, data_source:, user_id:, date:, seed:, context_prefix:)
        @cfg    = (client_config || {}).deep_stringify_keys
        @dq     = (data_quality_config || {}).deep_stringify_keys
        @ds     = data_source
        @uid    = user_id
        @date   = date
        @seed   = seed
        @prefix = context_prefix
      end

      def build!
        personal_id = FakeIdentifier.uuid
        first_name, last_name, name_dq = build_name
        ssn, ssn_dq                   = build_ssn
        dob, dob_dq                   = build_dob

        client = Hmis::Hud::Client.new(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @date.to_datetime,
          DateUpdated: @date.to_datetime,
          PersonalID: personal_id,
          FirstName: first_name,
          LastName: last_name,
          NameDataQuality: name_dq,
          SSN: ssn,
          SSNDataQuality: ssn_dq,
          DOB: dob,
          DOBDataQuality: dob_dq,
          VeteranStatus: build_veteran_status,
        )
        client.assign_attributes(build_gender_attributes)
        client.assign_attributes(build_race_attributes)
        client.save!

        custom_name = Hmis::Hud::CustomClientName.new(
          data_source_id: @ds.id,
          UserID: @uid,
          DateCreated: @date.to_datetime,
          DateUpdated: @date.to_datetime,
          CustomClientNameID: FakeIdentifier.uuid,
          PersonalID: personal_id,
          first: first_name,
          last: last_name,
          primary: true,
          use: :usual,
          NameDataQuality: name_dq,
        )
        custom_name.save!

        { client: client, custom_name: custom_name }
      end

      private

      def rng(sub_context)
        Random.new(@seed + "#{@prefix}:#{sub_context}".hash)
      end

      # -- Name --

      def build_name
        if roll_rate('missing_name_rate', 'name_missing')
          [nil, nil, 99]
        else
          [FakeIdentifier.first_name(rng: rng('first_name')), FakeIdentifier.last_name(rng: rng('last_name')), 1]
        end
      end

      # -- SSN --

      def build_ssn
        if roll_rate('missing_ssn_rate', 'ssn_missing')
          [nil, 99]
        else
          [FakeIdentifier.ssn, 1]
        end
      end

      # -- DOB --

      def build_dob
        if roll_rate('missing_dob_rate', 'dob_missing')
          [nil, 99]
        elsif roll_rate('approximate_dob_rate', 'dob_approximate')
          birth_year = @date.year - sample_age.to_i
          [Date.new(birth_year, 1, 1), 2]
        else
          [dob_from_age, 1]
        end
      end

      def dob_from_age
        age = sample_age
        @date - (age * 365.25).round
      end

      def sample_age
        age_cfg = @cfg['age'] || { 'distribution' => 'uniform', 'min' => 18, 'max' => 65 }
        Distribution.sample(age_cfg.deep_stringify_keys, rng: rng('age'))
      end

      # -- Veteran status --

      def build_veteran_status
        prob = @cfg['veteran_probability'].to_f
        age = sample_age
        return 0 if age < 18

        rng('veteran').rand < prob ? 1 : 0
      end

      # -- Gender --

      def build_gender_attributes
        defaults = GENDER_MAP.values.each_with_object({}) { |col, h| h[col] = 0 }
        gender_cfg = @cfg['gender']

        if gender_cfg.present?
          valid_weights = gender_cfg.slice(*GENDER_MAP.keys).transform_values(&:to_f)
          if valid_weights.values.sum.positive?
            cfg = { 'distribution' => 'weighted', 'weights' => valid_weights }
            selected = Distribution.sample(cfg, rng: rng('gender'))
            col = GENDER_MAP[selected]
            defaults[col] = 1 if col
            return defaults
          end
        end

        # Fallback: pick a random known gender
        col = GENDER_MAP.values.sample(random: rng('gender_fallback'))
        defaults[col] = 1
        defaults
      end

      # -- Race --

      def build_race_attributes
        defaults = RACE_MAP.values.each_with_object({}) { |col, h| h[col] = 0 }
        race_cfg = @cfg['race']

        if race_cfg.present?
          valid_weights = race_cfg.slice(*RACE_MAP.keys).transform_values(&:to_f)
          if valid_weights.values.sum.positive?
            cfg = { 'distribution' => 'weighted', 'weights' => valid_weights }
            selected = Distribution.sample(cfg, rng: rng('race'))
            col = RACE_MAP[selected]
            defaults[col] = 1 if col
            return defaults
          end
        end

        col = RACE_MAP.values.sample(random: rng('race_fallback'))
        defaults[col] = 1
        defaults
      end

      # -- Helpers --

      def roll_rate(config_key, context)
        rate = @dq[config_key].to_f
        return false if rate.zero?
        return true if rate >= 1.0

        rng(context).rand < rate
      end
    end
  end
end
