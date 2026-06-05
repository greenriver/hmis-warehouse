###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ConfigLoader do
  let(:valid_config) do
    {
      'name' => 'Test CoC',
      'data_source_id' => 1,
      'seed' => 12345,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Test Org_',
          'projects' => [
            { 'name' => 'Test ES NBN_', 'project_type' => 1, 'capacity' => 20 },
            { 'name' => 'Test PSH_', 'project_type' => 3, 'capacity' => 10 },
          ],
        },
      ],
      'populations' => [
        {
          'name' => 'street',
          'label' => 'Street',
          'project_ref' => 'Test ES NBN_',
          'household_templates' => { 'adult_only' => 1.0 },
          'entry_point' => 1,
          'exit_point' => 0.1,
        },
        {
          'name' => 'psh',
          'label' => 'PSH',
          'project_ref' => 'Test PSH_',
          'household_templates' => { 'adult_only' => 1.0 },
          'entry_point' => 0,
          'exit_point' => 0.5,
        },
      ],
      'transitions' => [
        {
          'from' => 'street', 'to' => 'psh',
          'weight' => 1,
          'timing' => { 'distribution' => 'constant', 'value' => 30 },
          'exit_destinations' => { '435' => 1.0 }
        },
      ],
      'enrollment_config' => {
        'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 5 },
      },
    }
  end

  describe '.from_app_config' do
    context 'when AppConfigProperty exists' do
      before do
        AppConfigProperty.where(key: 'hmis_simulation/test').delete_all
        AppConfigProperty.create!(key: 'hmis_simulation/test', value: valid_config)
      end

      it 'loads and returns the config hash' do
        config = described_class.from_app_config('hmis_simulation/test')
        expect(config['name']).to eq('Test CoC')
      end
    end

    context 'when AppConfigProperty does not exist' do
      it 'raises KeyError' do
        expect { described_class.from_app_config('hmis_simulation/missing') }.
          to raise_error(KeyError, /not found/i)
      end
    end
  end

  describe '.from_file' do
    it 'parses a JSON file and returns the config hash' do
      Tempfile.create(['sim_config', '.json']) do |f|
        f.write(valid_config.to_json)
        f.flush
        config = described_class.from_file(f.path)
        expect(config['name']).to eq('Test CoC')
      end
    end

    it 'raises if the file does not exist' do
      expect { described_class.from_file('/no/such/file.json') }.to raise_error(Errno::ENOENT)
    end
  end

  describe 'weight normalization' do
    it 'normalizes entry_point values to sum to 1.0' do
      Tempfile.create(['sim', '.json']) do |f|
        f.write(valid_config.to_json)
        f.flush
        config = described_class.from_file(f.path)
        entry_points = config['populations'].map { |p| p['entry_point'] }
        expect(entry_points.sum).to be_within(0.001).of(1.0)
      end
    end

    it 'normalizes transition weights within each from-population' do
      Tempfile.create(['sim', '.json']) do |f|
        f.write(valid_config.to_json)
        f.flush
        config = described_class.from_file(f.path)
        weights = config['transitions'].select { |t| t['from'] == 'street' }.map { |t| t['weight'] }
        expect(weights.sum).to be_within(0.001).of(1.0)
      end
    end

    it 'normalizes exit_destination weights' do
      Tempfile.create(['sim', '.json']) do |f|
        f.write(valid_config.to_json)
        f.flush
        config = described_class.from_file(f.path)
        dests = config['transitions'].first['exit_destinations']
        expect(dests.values.sum).to be_within(0.001).of(1.0)
      end
    end
  end

  describe 'AppConfigProperty upsert' do
    it 'creates the record if it does not exist' do
      AppConfigProperty.where(key: 'hmis_simulation/upsert_test').delete_all
      described_class.upsert_app_config('hmis_simulation/upsert_test', valid_config)
      expect(AppConfigProperty.find_by(key: 'hmis_simulation/upsert_test')).not_to be_nil
    end

    it 'updates the record if it already exists' do
      AppConfigProperty.where(key: 'hmis_simulation/upsert_test').delete_all
      described_class.upsert_app_config('hmis_simulation/upsert_test', valid_config)
      updated = valid_config.merge('name' => 'Updated')
      described_class.upsert_app_config('hmis_simulation/upsert_test', updated)
      record = AppConfigProperty.find_by(key: 'hmis_simulation/upsert_test')
      expect(record.value['name']).to eq('Updated')
    end
  end
end
