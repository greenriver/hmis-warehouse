###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::TableConfiguration, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }

  describe 'validations' do
    subject { build(:hmis_table_configuration_ce_clients, data_source: data_source) }
    it { is_expected.to validate_inclusion_of(:table_key).in_array(Hmis::TableConfiguration::TABLE_KEYS) }

    it 'validates uniqueness of table_key scoped to owner and data_source' do
      create(:hmis_table_configuration_ce_clients, owner: project, data_source: data_source)
      duplicate = build(:hmis_table_configuration_ce_clients, owner: project, data_source: data_source)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:table_key]).to include('must be unique per owner')
    end

    it 'allows same table_key for different owners' do
      project2 = create(:hmis_hud_project, data_source: data_source)
      create(:hmis_table_configuration_ce_clients, owner: project, data_source: data_source)
      duplicate = build(:hmis_table_configuration_ce_clients, owner: project2, data_source: data_source)

      expect(duplicate).to be_valid
    end

    it 'allows same table_key for different data_sources' do
      data_source2 = create(:hmis_data_source)
      create(:hmis_table_configuration_ce_clients, owner: project, data_source: data_source)
      duplicate = build(:hmis_table_configuration_ce_clients, owner: project, data_source: data_source2)

      expect(duplicate).to be_valid
    end
  end

  describe 'column validation' do
    let(:valid_columns) do
      [
        {
          'key' => 'cde.custom_assessment.my_prioritization_score',
          'type' => 'string',
          'label' => 'My Score',
        },
        {
          'key' => 'cde.custom_assessment.date_field',
          'type' => 'date',
          'label' => 'XYZ Date',
        },
      ]
    end

    let(:invalid_columns) do
      [
        {
          'key' => 'cde.custom_assessment.my_prioritization_score',
          'type' => 'invalid_type',
          'label' => 'My Score',
        },
      ]
    end

    it 'validates valid columns' do
      config = build(:hmis_table_configuration_ce_clients, columns: valid_columns, data_source: data_source)
      expect(config).to be_valid
    end

    it 'rejects invalid column types' do
      config = build(:hmis_table_configuration_ce_clients, columns: invalid_columns, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:columns]).to include('must be an array of hashes with keys "key" (string), "label" (string), and "type" (valid column type)')
    end

    it 'rejects columns without required keys' do
      invalid_columns = [{ 'key' => 'test' }] # missing 'label' and 'type'
      config = build(:hmis_table_configuration_ce_clients, columns: invalid_columns, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:columns]).to include('must be an array of hashes with keys "key" (string), "label" (string), and "type" (valid column type)')
    end

    it 'accepts empty columns array' do
      config = build(:hmis_table_configuration_ce_clients, columns: [], data_source: data_source)
      expect(config).to be_valid
    end
  end

  describe 'filter validation' do
    let(:valid_filters) do
      [
        {
          'key' => 'cde.custom_assessment.my_prioritization_score',
          'label' => 'My Score',
          'type' => 'select',
          'options' => [
            { 'code' => '1' },
            { 'code' => '2' },
            { 'code' => '3' },
          ],
        },
      ]
    end

    let(:invalid_filters) do
      [
        {
          'key' => 'cde.custom_assessment.my_prioritization_score',
          'label' => 'My Score',
          'type' => 'invalid_type',
        },
      ]
    end

    it 'validates valid filters' do
      config = build(:hmis_table_configuration_ce_clients, filters: valid_filters, data_source: data_source)
      expect(config).to be_valid
    end

    it 'rejects invalid filter types' do
      config = build(:hmis_table_configuration_ce_clients, filters: invalid_filters, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:filters]).to include('each filter must have a "type" (string)')
    end

    it 'rejects filters without required keys' do
      invalid_filters = [{ 'key' => 'test' }] # missing 'label' and 'type'
      config = build(:hmis_table_configuration_ce_clients, filters: invalid_filters, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:filters]).to include('each filter must have a "label" (string)')
    end

    it 'rejects select filters without options' do
      invalid_filters = [
        {
          'key' => 'test',
          'label' => 'Test',
          'type' => 'select',
        },
      ]
      config = build(:hmis_table_configuration_ce_clients, filters: invalid_filters, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:filters]).to include('select filters must have an "options" array')
    end

    it 'rejects invalid options in select filters' do
      invalid_filters = [
        {
          'key' => 'test',
          'label' => 'Test',
          'type' => 'select',
          'options' => [{ 'invalid' => 'option' }],
        },
      ]
      config = build(:hmis_table_configuration_ce_clients, filters: invalid_filters, data_source: data_source)
      expect(config).not_to be_valid
      expect(config.errors[:filters]).to include('each option in "options" must be a hash with "code" (string) and optional "label" (string)')
    end

    it 'accepts empty filters array' do
      config = build(:hmis_table_configuration_ce_clients, filters: [], data_source: data_source)
      expect(config).to be_valid
    end
  end
end
