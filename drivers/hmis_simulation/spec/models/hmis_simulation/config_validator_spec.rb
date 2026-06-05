###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::ConfigValidator do
  let(:valid_config) do
    {
      'name' => 'Test',
      'data_source_id' => 1,
      'seed' => 99,
      'coc_codes' => { 'primary' => 'XX-500' },
      'organizations' => [
        {
          'name' => 'Org_',
          'projects' => [
            { 'name' => 'ES NBN_', 'project_type' => 1 },
            { 'name' => 'PSH_', 'project_type' => 3 },
            { 'name' => 'SO_', 'project_type' => 4 },
          ],
        },
      ],
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
      'enrollment_config' => {
        'new_clients_per_month' => { 'distribution' => 'constant', 'value' => 5 },
      },
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

  describe 'data_source_id' do
    it 'is required and must be a positive integer' do
      v = described_class.new(valid_config.merge('data_source_id' => nil))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/data_source_id/i)
    end
  end

  describe 'seed' do
    it 'is required' do
      v = described_class.new(valid_config.except('seed'))
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/seed/i)
    end
  end

  describe 'project_ref resolution' do
    it 'errors when a population project_ref does not match any project name' do
      config = valid_config.deep_dup
      config['populations'].first['project_ref'] = 'No Such Project_'
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/project_ref/i)
    end
  end

  describe 'transition population references' do
    it 'errors when a transition from population does not exist' do
      config = valid_config.deep_dup
      config['transitions'].first['from'] = 'nonexistent'
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/transition.*nonexistent|nonexistent.*transition/i)
    end

    it 'errors when a transition to population does not exist' do
      config = valid_config.deep_dup
      config['transitions'].first['to'] = 'nonexistent'
      v = described_class.new(config)
      expect(v).not_to be_valid
    end
  end

  describe 'entry_point weights' do
    it 'errors when no population has entry_point > 0' do
      config = valid_config.deep_dup
      config['populations'].each { |p| p['entry_point'] = 0 }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/entry_point/i)
    end
  end

  describe 'lifecycle enrollment trigger_populations' do
    it 'errors when a trigger_population does not name a defined population' do
      config = valid_config.deep_dup
      config['lifecycle_enrollments'] = [
        {
          'name' => 'ce', 'project_ref' => 'ES NBN_',
          'trigger_populations' => ['ghost_population'],
          'trigger_probability' => 0.4,
          'close_conditions' => { 'housing_move_in' => 1.0 }
        },
      ]
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/ghost_population/i)
    end
  end

  describe 'concurrent enrollment project_refs' do
    it 'errors when a concurrent project name does not exist' do
      config = valid_config.deep_dup
      config['concurrent_enrollments'] = {
        'count_distribution' => { '0' => 1 },
        'projects' => [
          { 'name' => 'Missing Project_', 'project_type' => 4, 'selection_weight' => 1,
            'duration' => { 'distribution' => 'constant', 'value' => 30 } },
        ],
      }
      v = described_class.new(config)
      expect(v).not_to be_valid
      expect(v.errors.join).to match(/Missing Project_/i)
    end
  end
end
