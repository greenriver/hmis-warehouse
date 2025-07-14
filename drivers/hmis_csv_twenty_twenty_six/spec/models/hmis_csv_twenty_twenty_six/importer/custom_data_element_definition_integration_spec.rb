###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CustomDataElementDefinition Integration' do
  before(:all) do
    # Bootstrap custom models to ensure they exist
    HmisCsvTwentyTwentySix::CustomFileManager.bootstrap_custom_models!
  end

  describe 'CustomDataElementDefinition.csv column mapping' do
    let(:source_record) do
      {
        'RecordType' => 'Enrollment',
        'Label' => 'Assessment Type',
        'Key' => 'assessment_type',
        'FieldType' => 'string',
        'Repeats' => 'false',
        'UserID' => 'user123',
        'DateCreated' => '2024-01-01T10:00:00Z',
        'DateUpdated' => '2024-01-01T11:00:00Z',
        'DateDeleted' => nil,
        'ExportID' => 'export456',
      }
    end

    let(:mapped_attributes) { {} }
    let(:config) { HmisCsvTwentyTwentySix.custom_files_config.for('CustomDataElementDefinition.csv') }
    let(:columns) { config['columns'] }

    it 'successfully applies all column mappings' do
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Test the exact scenario from the user's manual test
      expect(mapped_attributes).to include(
        'owner_type' => 'GrdaWarehouse::Hud::Enrollment',
        'label' => 'Assessment Type',
        'key' => 'assessment_type',
        'field_type' => 'string',
        'repeats' => 'false',
      )
    end

    it 'handles default column mappings for standard fields' do
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Default mappings should use the same column name
      expect(mapped_attributes).to include(
        'UserID' => 'user123',
        'DateCreated' => '2024-01-01T10:00:00Z',
        'DateUpdated' => '2024-01-01T11:00:00Z',
        'DateDeleted' => nil,
        'ExportID' => 'export456',
      )
    end

    it 'maps all RecordType values correctly' do
      record_types = ['Client', 'Enrollment', 'Exit', 'Project', 'Organization']
      expected_mappings = {
        'Client' => 'GrdaWarehouse::Hud::Client',
        'Enrollment' => 'GrdaWarehouse::Hud::Enrollment',
        'Exit' => 'GrdaWarehouse::Hud::Exit',
        'Project' => 'GrdaWarehouse::Hud::Project',
        'Organization' => 'GrdaWarehouse::Hud::Organization',
      }

      record_types.each do |record_type|
        test_record = source_record.merge('RecordType' => record_type)
        test_mapped_attributes = {}

        HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(test_record, test_mapped_attributes, columns)

        expect(test_mapped_attributes['owner_type']).to eq(expected_mappings[record_type])
      end
    end

    it 'produces the same results as the manual test' do
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # This should match the exact output from the manual test
      expect(mapped_attributes.keys).to include(
        'owner_type',
        'label',
        'key',
        'field_type',
        'repeats',
        'UserID',
        'DateCreated',
        'DateUpdated',
        'DateDeleted',
        'ExportID',
      )

      # Value mapping transformation
      expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')

      # Direct mappings
      expect(mapped_attributes['label']).to eq('Assessment Type')
      expect(mapped_attributes['key']).to eq('assessment_type')
      expect(mapped_attributes['field_type']).to eq('string')
      expect(mapped_attributes['repeats']).to eq('false')

      # Default mappings
      expect(mapped_attributes['UserID']).to eq('user123')
      expect(mapped_attributes['DateCreated']).to eq('2024-01-01T10:00:00Z')
      expect(mapped_attributes['DateUpdated']).to eq('2024-01-01T11:00:00Z')
      expect(mapped_attributes['DateDeleted']).to be_nil
      expect(mapped_attributes['ExportID']).to eq('export456')
    end

    it 'correctly reports source and mapped attributes' do
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Verify source record is unchanged
      expect(source_record).to eq(
        {
          'RecordType' => 'Enrollment',
          'Label' => 'Assessment Type',
          'Key' => 'assessment_type',
          'FieldType' => 'string',
          'Repeats' => 'false',
          'UserID' => 'user123',
          'DateCreated' => '2024-01-01T10:00:00Z',
          'DateUpdated' => '2024-01-01T11:00:00Z',
          'DateDeleted' => nil,
          'ExportID' => 'export456',
        },
      )

      # Verify mapped attributes has correct transformations
      expect(mapped_attributes.size).to be > 0
      expect(mapped_attributes).to be_a(Hash)
      expect(mapped_attributes).to have_key('owner_type')
      expect(mapped_attributes).not_to have_key('RecordType')
    end
  end

  describe 'CustomDataElementDefinition importer class' do
    let(:custom_importer_class) { HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElementDefinition }

    it 'exists and is properly configured' do
      expect(custom_importer_class).to be_a(Class)
      expect(custom_importer_class.included_modules).to include(HmisCsvTwentyTwentySix::Importer::Custom::CustomImportConcern)
    end

    it 'has correct upsert_column_names' do
      column_names = custom_importer_class.upsert_column_names

      expect(column_names).to include(:owner_type)
      expect(column_names).to include(:label)
      expect(column_names).to include(:key)
      expect(column_names).to include(:field_type)
      expect(column_names).to include(:repeats)
      expect(column_names).to include(:UserID)

      # Should exclude the standard excluded columns
      expect(column_names).not_to include(:DateCreated)
      expect(column_names).not_to include(:DateUpdated)
      expect(column_names).not_to include(:DateDeleted)
      expect(column_names).not_to include(:ExportID)
    end
  end

  describe 'Configuration validation' do
    it 'has a valid configuration for CustomDataElementDefinition.csv' do
      config = HmisCsvTwentyTwentySix.custom_files_config.for('CustomDataElementDefinition.csv')

      expect(config).to be_present
      expect(config['filename']).to eq('CustomDataElementDefinition.csv')
      expect(config['class_name']).to eq('CustomDataElementDefinition')
      expect(config['columns']).to be_an(Array)
      expect(config['columns'].length).to be > 0
    end

    it 'has proper warehouse column mappings configured' do
      config = HmisCsvTwentyTwentySix.custom_files_config.for('CustomDataElementDefinition.csv')
      columns = config['columns']

      # Find RecordType column
      record_type_col = columns.find { |col| col['name'] == 'RecordType' }
      expect(record_type_col).to be_present
      expect(record_type_col['warehouse_column_mapping']).to be_present
      expect(record_type_col['warehouse_column_mapping']['type']).to eq('value_mapping')
      expect(record_type_col['warehouse_column_mapping']['target_column']).to eq('owner_type')
      expect(record_type_col['warehouse_column_mapping']['value_mappings']).to be_present

      # Find Label column
      label_col = columns.find { |col| col['name'] == 'Label' }
      expect(label_col).to be_present
      expect(label_col['warehouse_column_mapping']).to be_present
      expect(label_col['warehouse_column_mapping']['type']).to eq('direct')
      expect(label_col['warehouse_column_mapping']['target_column']).to eq('label')

      # Find UserID column (should have no explicit mapping)
      user_id_col = columns.find { |col| col['name'] == 'UserID' }
      expect(user_id_col).to be_present
      expect(user_id_col['warehouse_column_mapping']).to be_nil
    end
  end

  describe 'Real-world scenario simulation' do
    it 'processes a complete record as it would in production' do
      source_record = {
        'CustomDataElementDefinitionID' => 'def123',
        'RecordType' => 'Client',
        'Label' => 'Housing Status',
        'Key' => 'housing_status',
        'FieldType' => 'string',
        'Repeats' => 'true',
        'UserID' => 'admin_user',
        'DateCreated' => '2024-01-15T09:30:00Z',
        'DateUpdated' => '2024-01-15T09:30:00Z',
        'DateDeleted' => nil,
        'ExportID' => 'exp789',
      }

      mapped_attributes = {}
      config = HmisCsvTwentyTwentySix.custom_files_config.for('CustomDataElementDefinition.csv')
      columns = config['columns']

      HmisCsvTwentyTwentySix::Importer::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Verify the complete transformation
      expect(mapped_attributes).to eq(
        {
          'CustomDataElementDefinitionID' => 'def123',
          'owner_type' => 'GrdaWarehouse::Hud::Client',
          'label' => 'Housing Status',
          'key' => 'housing_status',
          'field_type' => 'string',
          'repeats' => 'true',
          'UserID' => 'admin_user',
          'DateCreated' => '2024-01-15T09:30:00Z',
          'DateUpdated' => '2024-01-15T09:30:00Z',
          'DateDeleted' => nil,
          'ExportID' => 'exp789',
        },
      )
    end
  end
end
