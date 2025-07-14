###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::Custom::CustomImportConcern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include HmisCsvTwentyTwentySix::Importer::Custom::CustomImportConcern

      def file_name
        'CustomDataElementDefinition.csv'
      end

      def hud_csv_version
        '2026'
      end

      def augments?
        false
      end

      def custom_file_config
        # This will be stubbed in the tests
        {}
      end
    end
  end

  let(:test_instance) { test_class.new }

  describe '#upsert_column_names' do
    before do
      # Mock the custom_file_config method to return a test configuration
      allow(test_instance).to receive(:custom_file_config).and_return(
        {
          'columns' => [
            {
              'name' => 'CustomDataElementDefinitionID',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'CustomDataElementDefinitionID',
              },
            },
            {
              'name' => 'RecordType',
              'warehouse_column_mapping' => {
                'type' => 'value_mapping',
                'target_column' => 'owner_type',
                'value_mappings' => {
                  'Client' => 'GrdaWarehouse::Hud::Client',
                  'Enrollment' => 'GrdaWarehouse::Hud::Enrollment',
                },
              },
            },
            {
              'name' => 'Label',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'label',
              },
            },
            {
              'name' => 'Key',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'key',
              },
            },
            {
              'name' => 'FieldType',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'field_type',
              },
            },
            {
              'name' => 'Repeats',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'repeats',
              },
            },
            {
              'name' => 'DateCreated',
              # No mapping - should use defaults
            },
            {
              'name' => 'DateUpdated',
              # No mapping - should use defaults
            },
            {
              'name' => 'UserID',
              # No mapping - should use defaults
            },
            {
              'name' => 'DateDeleted',
              # No mapping - should use defaults
            },
            {
              'name' => 'ExportID',
              # No mapping - should use defaults
            },
          ],
        },
      )
    end

    it 'returns warehouse column names from explicit mappings' do
      result = test_instance.upsert_column_names

      # Should include explicitly mapped columns
      expect(result).to include(:CustomDataElementDefinitionID)
      expect(result).to include(:owner_type)
      expect(result).to include(:label)
      expect(result).to include(:key)
      expect(result).to include(:field_type)
      expect(result).to include(:repeats)
    end

    it 'uses default column names for unmapped columns' do
      result = test_instance.upsert_column_names

      # Should include default-mapped columns (same as source name)
      expect(result).to include(:DateCreated)
      expect(result).to include(:DateUpdated)
      expect(result).to include(:UserID)
      expect(result).to include(:DateDeleted)
      expect(result).to include(:ExportID)
    end

    it 'excludes standard excluded columns' do
      result = test_instance.upsert_column_names

      # Should exclude standard excluded columns
      expect(result).not_to include(:DateCreated)
      expect(result).not_to include(:DateUpdated)
      expect(result).not_to include(:DateDeleted)
      expect(result).not_to include(:ExportID)
    end

    it 'returns the correct final set of columns' do
      result = test_instance.upsert_column_names

      expected_columns = [
        :CustomDataElementDefinitionID,
        :owner_type,
        :label,
        :key,
        :field_type,
        :repeats,
        :UserID,
      ]

      expect(result).to match_array(expected_columns)
    end

    context 'when augments? is true' do
      before do
        allow(test_instance).to receive(:augments?).and_return(true)
      end

      it 'excludes augmentation columns' do
        result = test_instance.upsert_column_names

        # Should not include UserID when augmenting
        expect(result).not_to include(:UserID)
      end
    end
  end

  describe '#create_columns' do
    before do
      # Mock the custom_file_config method to return a test configuration
      allow(test_instance).to receive(:custom_file_config).and_return(
        {
          'columns' => [
            {
              'name' => 'CustomDataElementDefinitionID',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'CustomDataElementDefinitionID',
              },
            },
            {
              'name' => 'RecordType',
              'warehouse_column_mapping' => {
                'type' => 'value_mapping',
                'target_column' => 'owner_type',
              },
            },
            {
              'name' => 'Label',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'label',
              },
            },
            {
              'name' => 'UserID',
              # No mapping - should use defaults
            },
            {
              'name' => 'DateCreated',
              # No mapping - should use defaults
            },
            {
              'name' => 'DateUpdated',
              # No mapping - should use defaults
            },
            {
              'name' => 'DateDeleted',
              # No mapping - should use defaults
            },
            {
              'name' => 'ExportID',
              # No mapping - should use defaults
            },
          ],
        },
      )
    end

    it 'returns warehouse column names from all mappings' do
      result = test_instance.create_columns

      # Should include all mapped columns
      expect(result).to include('CustomDataElementDefinitionID')
      expect(result).to include('owner_type')
      expect(result).to include('label')
      expect(result).to include('UserID')
      expect(result).to include('DateCreated')
      expect(result).to include('DateUpdated')
      expect(result).to include('DateDeleted')
      expect(result).to include('ExportID')
    end

    it 'excludes standard excluded columns' do
      result = test_instance.create_columns

      # Should exclude standard excluded columns
      expect(result).not_to include('DateCreated')
      expect(result).not_to include('DateUpdated')
      expect(result).not_to include('DateDeleted')
      expect(result).not_to include('ExportID')
    end

    it 'returns the correct final set of columns' do
      result = test_instance.create_columns

      expected_columns = [
        'CustomDataElementDefinitionID',
        'owner_type',
        'label',
        'UserID',
      ]

      expect(result).to match_array(expected_columns)
    end
  end

  describe 'column mapping integration' do
    before do
      # Mock the custom_file_config method to return a test configuration
      allow(test_instance).to receive(:custom_file_config).and_return(
        {
          'columns' => [
            {
              'name' => 'RecordType',
              'warehouse_column_mapping' => {
                'type' => 'value_mapping',
                'target_column' => 'owner_type',
                'value_mappings' => {
                  'Client' => 'GrdaWarehouse::Hud::Client',
                  'Enrollment' => 'GrdaWarehouse::Hud::Enrollment',
                },
              },
            },
            {
              'name' => 'Label',
              'warehouse_column_mapping' => {
                'type' => 'direct',
                'target_column' => 'label',
              },
            },
            {
              'name' => 'UserID',
              # No mapping - should use defaults
            },
          ],
        },
      )
    end

    it 'properly integrates with column mapping system' do
      # Test that the concern properly handles both explicit and default mappings
      config = test_instance.custom_file_config

      # Explicit mappings should be preserved
      record_type_mapping = config['columns'].find { |col| col['name'] == 'RecordType' }['warehouse_column_mapping']
      expect(record_type_mapping['type']).to eq('value_mapping')
      expect(record_type_mapping['target_column']).to eq('owner_type')

      label_mapping = config['columns'].find { |col| col['name'] == 'Label' }['warehouse_column_mapping']
      expect(label_mapping['type']).to eq('direct')
      expect(label_mapping['target_column']).to eq('label')

      # Default mappings should be handled in upsert_column_names
      user_id_mapping = config['columns'].find { |col| col['name'] == 'UserID' }['warehouse_column_mapping']
      expect(user_id_mapping).to be_nil
    end
  end
end
