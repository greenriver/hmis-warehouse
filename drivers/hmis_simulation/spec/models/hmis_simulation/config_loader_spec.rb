###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ConfigLoader do
  let(:primary_track) do
    {
      'name' => 'general',
      'type' => 'primary',
      'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 5 },
      'household_templates' => {
        'adult_only' => { 'hoh' => { 'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 } } },
      },
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
    }
  end

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
      'tracks' => [primary_track],
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
      expect { described_class.from_file('/no/such/file.json') }.to raise_error(KeyError, /not found/)
    end
  end

  describe 'per-track weight normalization' do
    subject(:config) { described_class.send(:normalize, valid_config) }

    let(:primary) { config['tracks'].find { |t| t['type'] == 'primary' } }

    it 'normalizes entry_point values within a primary track to sum to 1.0' do
      entry_points = primary['populations'].map { |p| p['entry_point'] }
      expect(entry_points.sum).to be_within(0.001).of(1.0)
    end

    it 'normalizes transition weights within each from-population' do
      weights = primary['transitions'].select { |t| t['from'] == 'street' }.map { |t| t['weight'] }
      expect(weights.sum).to be_within(0.001).of(1.0)
    end

    it 'normalizes exit_destination weights within each transition' do
      dests = primary['transitions'].first['exit_destinations']
      expect(dests.values.sum).to be_within(0.001).of(1.0)
    end

    context 'with a concurrent track' do
      let(:config_with_concurrent) do
        valid_config.deep_dup.tap do |c|
          c['organizations'].first['projects'] << { 'name' => 'SO_', 'project_type' => 4 }
          c['tracks'] << {
            'name' => 'so_contacts',
            'type' => 'concurrent',
            'projects' => ['SO_'],
            'count_distribution' => { '0' => 55, '1' => 30, '2' => 15 },
            'duration' => { 'distribution' => 'constant', 'value' => 30 },
          }
        end
      end

      it 'normalizes count_distribution within a concurrent track' do
        normalized = described_class.send(:normalize, config_with_concurrent)
        concurrent = normalized['tracks'].find { |t| t['type'] == 'concurrent' }
        expect(concurrent['count_distribution'].values.sum).to be_within(0.001).of(1.0)
      end
    end

    it 'normalizes each primary track independently when multiple primaries exist' do
      multi_config = valid_config.deep_dup
      multi_config['organizations'].first['projects'] << { 'name' => 'Vet ES_', 'project_type' => 1 }
      multi_config['tracks'] << {
        'name' => 'veterans',
        'type' => 'primary',
        'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 2 },
        'household_templates' => { 'adult_only' => { 'hoh' => {} } },
        'populations' => [
          { 'name' => 'vet_street', 'project_ref' => 'Vet ES_',
            'entry_point' => 3, 'exit_point' => 0.1 },
          { 'name' => 'vet_psh', 'project_ref' => 'Test PSH_',
            'entry_point' => 7, 'exit_point' => 0.5 },
        ],
        'transitions' => [],
      }

      normalized = described_class.send(:normalize, multi_config)

      normalized['tracks'].select { |t| t['type'] == 'primary' }.each do |track|
        ep_sum = track['populations'].sum { |p| p['entry_point'] }
        expect(ep_sum).to be_within(0.001).of(1.0), "#{track['name']} entry_points do not sum to 1.0"
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
