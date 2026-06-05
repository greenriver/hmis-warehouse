###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::ClientBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) { User.setup_system_user.tap { Hmis::Hud::User.system_user(data_source_id: data_source.id) } && Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id }
  let(:date) { Date.new(2026, 1, 15) }
  let(:seed) { 42 }

  let(:hoh_config) do
    {
      'age' => { 'distribution' => 'normal', 'mean' => 40, 'stddev' => 10, 'min' => 18 },
      'gender' => { 'woman' => 0.5, 'man' => 0.5 },
      'veteran_probability' => 0.1,
      'race' => { 'white' => 0.5, 'black_af_american' => 0.5 },
    }
  end

  let(:data_quality_config) { {} }

  subject(:builder) do
    described_class.new(
      client_config: hoh_config,
      data_quality_config: data_quality_config,
      data_source: data_source,
      user_id: user_id,
      date: date,
      seed: seed,
      context_prefix: 'test:client:0',
    )
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::Client record' do
      expect { builder.build! }.to change { Hmis::Hud::Client.where(data_source: data_source).count }.by(1)
    end

    it 'creates an Hmis::Hud::CustomClientName record linked to the client' do
      result = builder.build!
      expect(result[:custom_name].PersonalID).to eq(result[:client].PersonalID)
      expect(result[:custom_name].primary).to be true
    end

    it 'assigns a FAKE PersonalID' do
      result = builder.build!
      expect(result[:client].PersonalID).to start_with('FAKE')
      expect(result[:client].PersonalID.length).to eq(32)
    end

    it 'assigns a 999-prefixed SSN' do
      result = builder.build!
      expect(result[:client].SSN).to start_with('999')
    end

    it 'assigns city name with trailing underscore as FirstName' do
      result = builder.build!
      expect(result[:client].FirstName).to end_with('_')
      expect(result[:client].FirstName.length).to be > 1
    end

    it 'assigns river name with trailing underscore as LastName' do
      result = builder.build!
      expect(result[:client].LastName).to end_with('_')
      expect(result[:client].LastName.length).to be > 1
    end

    it 'sets a DOB consistent with the configured age distribution (min 18)' do
      result = builder.build!
      age_on_date = ((date - result[:client].DOB) / 365.25).to_i
      expect(age_on_date).to be >= 18
    end

    it 'sets NameDataQuality to 1 (full data) by default' do
      result = builder.build!
      expect(result[:client].NameDataQuality).to eq(1)
    end

    it 'sets DOBDataQuality to 1 (full data) by default' do
      result = builder.build!
      expect(result[:client].DOBDataQuality).to eq(1)
    end

    it 'sets SSNDataQuality to 1 (full data) by default' do
      result = builder.build!
      expect(result[:client].SSNDataQuality).to eq(1)
    end

    context 'with missing_dob_rate: 1.0' do
      let(:data_quality_config) { { 'missing_dob_rate' => 1.0 } }

      it 'sets DOB to nil and DOBDataQuality to 99' do
        result = builder.build!
        expect(result[:client].DOB).to be_nil
        expect(result[:client].DOBDataQuality).to eq(99)
      end
    end

    context 'with approximate_dob_rate: 1.0' do
      let(:data_quality_config) { { 'approximate_dob_rate' => 1.0 } }

      it 'sets DOB to Jan 1 of birth year and DOBDataQuality to 2' do
        result = builder.build!
        expect(result[:client].DOB.month).to eq(1)
        expect(result[:client].DOB.day).to eq(1)
        expect(result[:client].DOBDataQuality).to eq(2)
      end
    end

    context 'with missing_ssn_rate: 1.0' do
      let(:data_quality_config) { { 'missing_ssn_rate' => 1.0 } }

      it 'sets SSN to nil and SSNDataQuality to 99' do
        result = builder.build!
        expect(result[:client].SSN).to be_nil
        expect(result[:client].SSNDataQuality).to eq(99)
      end
    end

    context 'with missing_name_rate: 1.0' do
      let(:data_quality_config) { { 'missing_name_rate' => 1.0 } }

      it 'sets FirstName and LastName to nil and NameDataQuality to 99' do
        result = builder.build!
        expect(result[:client].FirstName).to be_nil
        expect(result[:client].LastName).to be_nil
        expect(result[:client].NameDataQuality).to eq(99)
      end
    end

    it 'assigns at least one gender field' do
      result = builder.build!
      gender_fields = HudHelper.util.gender_fields.map(&:to_s) - ['GenderNone']
      any_set = gender_fields.any? { |f| result[:client].send(f) == 1 }
      expect(any_set).to be true
    end

    it 'assigns at least one race field' do
      result = builder.build!
      race_fields = HudHelper.util.race_fields.map(&:to_s) - ['RaceNone']
      any_set = race_fields.any? { |f| result[:client].send(f) == 1 }
      expect(any_set).to be true
    end

    it 'returns a hash with :client and :custom_name keys' do
      result = builder.build!
      expect(result).to include(:client, :custom_name)
      expect(result[:client]).to be_a(Hmis::Hud::Client)
      expect(result[:custom_name]).to be_a(Hmis::Hud::CustomClientName)
    end

    it 'is deterministic — same seed + context produces same name' do
      r1 = described_class.new(
        client_config: hoh_config, data_quality_config: {}, data_source: data_source,
        user_id: user_id, date: date, seed: 99, context_prefix: 'ctx:1'
      ).build!

      # Different data source to avoid uniqueness constraint on PersonalID
      ds2 = create(:hmis_data_source)
      User.setup_system_user
      uid2 = Hmis::Hud::User.system_user(data_source_id: ds2.id).user_id
      r2 = described_class.new(
        client_config: hoh_config, data_quality_config: {}, data_source: ds2,
        user_id: uid2, date: date, seed: 99, context_prefix: 'ctx:1'
      ).build!

      expect(r1[:client].FirstName).to eq(r2[:client].FirstName)
      expect(r1[:client].LastName).to eq(r2[:client].LastName)
    end
  end
end
