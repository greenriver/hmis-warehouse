###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ConfigValidator do
  let(:base_projects) do
    [
      { 'name' => 'ES NBN_', 'project_type' => 1 },
      { 'name' => 'PSH_', 'project_type' => 3 },
      { 'name' => 'SO_', 'project_type' => 4 },
      { 'name' => 'CE_', 'project_type' => 14 },
    ]
  end

  let(:primary_track) do
    {
      'name' => 'general',
      'type' => 'primary',
      'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 5 },
      'household_templates' => {
        'adult_only' => { 'hoh' => { 'age' => { 'distribution' => 'uniform', 'min' => 25, 'max' => 55 } } },
      },
      'populations' => [
        { 'name' => 'street', 'label' => 'Street', 'project_ref' => 'SO_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 1, 'exit_point' => 0.1 },
        { 'name' => 'psh', 'label' => 'PSH', 'project_ref' => 'PSH_',
          'household_templates' => { 'adult_only' => 1 },
          'entry_point' => 0, 'exit_point' => 0.5 },
      ],
      'transitions' => [
        { 'from' => 'street', 'to' => 'psh', 'weight' => 1,
          'timing' => { 'distribution' => 'constant', 'value' => 30 },
          'exit_destinations' => { '435' => 1 } },
      ],
    }
  end

  let(:valid_config) do
    {
      'name' => 'Test',
      'data_source_id' => 1,
      'seed' => 99,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        { 'name' => 'Org_', 'projects' => base_projects },
      ],
      'tracks' => [primary_track],
    }
  end

  subject(:validator) { described_class.new(valid_config) }

  describe '#valid?' do
    it 'returns true for a valid config' do
      expect(validator).to be_valid
    end

    it 'returns false and populates errors when config is invalid' do
      bad = valid_config.merge('data_source_id' => nil)
      v = described_class.new(bad)
      expect(v).not_to be_valid
      expect(v.errors).not_to be_empty
    end
  end

  describe 'schema validation' do
    it 'errors when data_source_id is not a positive integer' do
      v = described_class.new(valid_config.merge('data_source_id' => nil))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/data_source_id/i)
    end

    it 'errors when seed is missing' do
      v = described_class.new(valid_config.except('seed'))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/seed/i)
    end

    it 'errors when tracks is missing' do
      v = described_class.new(valid_config.except('tracks'))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/tracks/i)
    end

    it 'errors when a track has an invalid type' do
      config = valid_config.deep_dup
      config['tracks'].first['type'] = 'invalid'
      v = described_class.new(config)
      expect(v).not_to be_valid
    end

    it 'errors when a primary track is missing new_clients_per_month' do
      config = valid_config.deep_dup
      config['tracks'].first.delete('new_clients_per_month')
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/new_clients_per_month/i)
    end

    it 'errors when a primary track is missing populations' do
      config = valid_config.deep_dup
      config['tracks'].first.delete('populations')
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/populations/i)
    end

    it 'errors when a concurrent track is missing duration' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'so_contacts',
        'type' => 'concurrent',
        'projects' => ['SO_'],
        'count_distribution' => { '0' => 1 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/duration/i)
    end

    it 'errors when a lifecycle track is missing project_ref' do
      config = valid_config.deep_dup
      config['organizations'].first['projects'] << { 'name' => 'CE_', 'project_type' => 14 }
      config['tracks'] << {
        'name' => 'coordinated_entry',
        'type' => 'lifecycle',
        'trigger_populations' => ['street'],
        'trigger_probability' => 0.4,
        'close_conditions' => { 'housing_move_in' => 1.0 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/project_ref/i)
    end
  end

  describe 'semantic: at least one primary track' do
    it 'errors when tracks has no primary type entry' do
      config = valid_config.deep_dup
      config['tracks'] = [
        {
          'name' => 'so_contacts',
          'type' => 'concurrent',
          'projects' => ['SO_'],
          'count_distribution' => { '0' => 1 },
          'duration' => { 'distribution' => 'constant', 'value' => 30 },
        },
      ]
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/primary/i)
    end
  end

  describe 'semantic: project_ref resolution' do
    it 'errors when a population project_ref does not match any project name' do
      config = valid_config.deep_dup
      config['tracks'].first['populations'].first['project_ref'] = 'No Such Project_'
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/project_ref/i)
    end
  end

  describe 'semantic: transition population references' do
    it 'errors when a transition from population does not exist in the same track' do
      config = valid_config.deep_dup
      config['tracks'].first['transitions'].first['from'] = 'nonexistent'
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/nonexistent/i)
    end

    it 'errors when a transition to population does not exist in the same track' do
      config = valid_config.deep_dup
      config['tracks'].first['transitions'].first['to'] = 'nonexistent'
      v = described_class.new(config)
      expect(v).not_to be_valid
    end
  end

  describe 'semantic: entry_point weights' do
    it 'errors when no population in a primary track has entry_point > 0' do
      config = valid_config.deep_dup
      config['tracks'].first['populations'].each { |p| p['entry_point'] = 0 }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/entry_point/i)
    end
  end

  describe 'semantic: lifecycle trigger_populations' do
    it 'errors when a trigger_population does not name a population in any primary track' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'coordinated_entry',
        'type' => 'lifecycle',
        'project_ref' => 'CE_',
        'trigger_populations' => ['ghost_population'],
        'trigger_probability' => 0.4,
        'close_conditions' => { 'housing_move_in' => 1.0 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/ghost_population/i)
    end

    it 'errors when a lifecycle project_ref does not match any project name' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'coordinated_entry',
        'type' => 'lifecycle',
        'project_ref' => 'Missing CE Project_',
        'trigger_populations' => ['street'],
        'trigger_probability' => 0.4,
        'close_conditions' => { 'housing_move_in' => 1.0 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/Missing CE Project_/i)
    end
  end

  describe 'semantic: concurrent track project references' do
    it 'errors when a concurrent track project does not exist in organizations' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'bad_concurrent',
        'type' => 'concurrent',
        'projects' => ['Missing Project_'],
        'count_distribution' => { '0' => 1 },
        'duration' => { 'distribution' => 'constant', 'value' => 30 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/Missing Project_/i)
    end
  end

  describe 'semantic: applies_to_tracks' do
    it 'errors when applies_to_tracks references a non-existent primary track' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'so_contacts',
        'type' => 'concurrent',
        'applies_to_tracks' => ['nonexistent_track'],
        'projects' => ['SO_'],
        'count_distribution' => { '0' => 1 },
        'duration' => { 'distribution' => 'constant', 'value' => 30 },
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/nonexistent_track/i)
    end

    it 'is valid when applies_to_tracks names an existing primary track' do
      config = valid_config.deep_dup
      config['tracks'] << {
        'name' => 'so_contacts',
        'type' => 'concurrent',
        'applies_to_tracks' => ['general'],
        'projects' => ['SO_'],
        'count_distribution' => { '0' => 1 },
        'duration' => { 'distribution' => 'constant', 'value' => 30 },
      }
      v = described_class.new(config)
      expect(v).to be_valid
    end
  end

  describe 'prior_living_situation validation' do
    def config_with_prior_living_situation(weights)
      config = valid_config.deep_dup
      config['tracks'][0]['populations'][0]['prior_living_situation'] = {
        'distribution' => 'weighted',
        'weights' => weights,
      }
      config
    end

    it 'is valid when prior_living_situation uses known HUD codes' do
      v = described_class.new(config_with_prior_living_situation('116' => 60, '101' => 40))
      expect(v).to be_valid
    end

    it 'errors when prior_living_situation uses an invalid HUD code' do
      v = described_class.new(config_with_prior_living_situation('9999' => 1))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/9999/)
    end

    it 'errors when prior_living_situation uses a non-numeric key' do
      v = described_class.new(config_with_prior_living_situation('homeless' => 1))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/homeless/)
    end
  end
end
