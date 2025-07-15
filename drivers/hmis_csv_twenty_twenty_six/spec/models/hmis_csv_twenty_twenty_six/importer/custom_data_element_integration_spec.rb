###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CustomDataElement Integration' do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:importer_log) { create(:hmis_csv_importer_log, data_source: data_source) }
  let(:config) { HmisCsvTwentyTwentySix.custom_files_config.for('CustomDataElement.csv') }
  let(:columns) { config['columns'] }

  # Create test warehouse records to lookup
  let!(:test_client) { create(:grda_warehouse_hud_client, data_source: data_source, PersonalID: 'CLIENT123') }
  let!(:test_enrollment) { create(:grda_warehouse_hud_enrollment, data_source: data_source, EnrollmentID: 'ENROLL456', PersonalID: test_client.PersonalID) }

  describe 'CustomDataElement.csv column mapping' do
    let(:source_record) do
      HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
        CustomDataElementID: 'CDE001',
        CustomDataElementDefinitionID: 'DEF123',
        RecordType: 'Client',
        RecordID: 'CLIENT123',
        Value: 'test_value',
        DataCollectionStage: 1,
        InformationDate: Date.parse('2024-01-01'),
        UserID: 'user123',
        DateCreated: DateTime.parse('2024-01-01T10:00:00Z'),
        DateUpdated: DateTime.parse('2024-01-01T11:00:00Z'),
        DateDeleted: nil,
        ExportID: 'export456',
        data_source_id: data_source.id,
        importer_log_id: importer_log.id,
      )
    end

    let(:mapped_attributes) { {} }

    it 'successfully applies all column mappings including record lookup' do
      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Test the record type mapping
      expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')

      # Test the record lookup mapping
      expect(mapped_attributes['owner_id']).to eq(test_client.id)

      # Test direct mappings - use more flexible date/time matching
      expect(mapped_attributes['CustomDataElementID']).to eq('CDE001')
      expect(mapped_attributes['CustomDataElementDefinitionID']).to eq('DEF123')
      expect(mapped_attributes['Value']).to eq('test_value')
      expect(mapped_attributes['DataCollectionStage']).to eq(1)
      expect(mapped_attributes['UserID']).to eq('user123')
      expect(mapped_attributes['ExportID']).to eq('export456')
      expect(mapped_attributes['DateDeleted']).to be_nil

      # Test dates with more flexible matching - allow both Date and DateTime
      expect(mapped_attributes['InformationDate']).to be_a_kind_of(Time) # ActiveRecord often converts to Time/DateTime
      expect(mapped_attributes['InformationDate'].to_date.to_fs(:db)).to eq('2024-01-01')

      expect(mapped_attributes['DateCreated']).to be_a_kind_of(Time) # ActiveRecord often converts to Time/DateTime
      expect(mapped_attributes['DateCreated'].utc.to_fs(:db)).to eq('2024-01-01 10:00:00')

      expect(mapped_attributes['DateUpdated']).to be_a_kind_of(Time) # ActiveRecord often converts to Time/DateTime
      expect(mapped_attributes['DateUpdated'].utc.to_fs(:db)).to eq('2024-01-01 11:00:00')
    end

    it 'handles different record types and lookups correctly' do
      record_type_tests = [
        {
          record_type: 'Client',
          record_id: 'CLIENT123',
          expected_class: 'GrdaWarehouse::Hud::Client',
          expected_id: test_client.id,
        },
        {
          record_type: 'Enrollment',
          record_id: 'ENROLL456',
          expected_class: 'GrdaWarehouse::Hud::Enrollment',
          expected_id: test_enrollment.id,
        },
      ]

      record_type_tests.each do |test_case|
        test_record = source_record.dup
        test_record.RecordType = test_case[:record_type]
        test_record.RecordID = test_case[:record_id]
        test_mapped_attributes = {}

        HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(test_record, test_mapped_attributes, columns)

        expect(test_mapped_attributes['owner_type']).to eq(test_case[:expected_class])
        expect(test_mapped_attributes['owner_id']).to eq(test_case[:expected_id])
      end
    end

    it 'handles missing record lookups gracefully' do
      missing_record = source_record.dup
      missing_record.RecordID = 'MISSING123'

      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(missing_record, mapped_attributes, columns)

      expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
      expect(mapped_attributes['owner_id']).to be_nil
    end

    it 'handles default column mappings for standard fields' do
      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Default mappings should use the same column name
      expect(mapped_attributes['UserID']).to eq('user123')
      expect(mapped_attributes['ExportID']).to eq('export456')
      expect(mapped_attributes['DateDeleted']).to be_nil

      # Use flexible date matching - allow Time/DateTime objects
      expect(mapped_attributes['DateCreated']).to be_a_kind_of(Time)
      expect(mapped_attributes['DateUpdated']).to be_a_kind_of(Time)
    end

    it 'correctly reports source and mapped attributes with record lookup' do
      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Verify source record is unchanged
      expect(source_record.RecordType).to eq('Client')
      expect(source_record.RecordID).to eq('CLIENT123')

      # Verify mapped attributes has correct transformations
      expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
      expect(mapped_attributes['owner_id']).to eq(test_client.id)
      expect(mapped_attributes).not_to have_key('RecordType')
      expect(mapped_attributes).not_to have_key('RecordID')
    end
  end

  describe 'Batch processing' do
    let(:source_records) do
      [
        HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
          CustomDataElementID: 'CDE001',
          CustomDataElementDefinitionID: 'DEF123',
          RecordType: 'Client',
          RecordID: 'CLIENT123',
          Value: 'value1',
          UserID: 'user1',
          data_source_id: data_source.id,
          importer_log_id: importer_log.id,
        ),
        HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
          CustomDataElementID: 'CDE002',
          CustomDataElementDefinitionID: 'DEF124',
          RecordType: 'Enrollment',
          RecordID: 'ENROLL456',
          Value: 'value2',
          UserID: 'user2',
          data_source_id: data_source.id,
          importer_log_id: importer_log.id,
        ),
        HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
          CustomDataElementID: 'CDE003',
          CustomDataElementDefinitionID: 'DEF125',
          RecordType: 'Client',
          RecordID: 'MISSING123',
          Value: 'value3',
          UserID: 'user3',
          data_source_id: data_source.id,
          importer_log_id: importer_log.id,
        ),
      ]
    end

    it 'detects record lookups correctly' do
      has_lookups = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.record_lookups?(columns)
      expect(has_lookups).to be true
    end

    it 'processes batch mappings efficiently' do
      # Use the actual batch API
      results = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings_batch(source_records, columns)

      # Verify we get results for all records
      expect(results.length).to eq(3)

      # Verify lookups were resolved correctly
      expect(results[0]['owner_id']).to eq(test_client.id)
      expect(results[0]['owner_type']).to eq('GrdaWarehouse::Hud::Client')

      expect(results[1]['owner_id']).to eq(test_enrollment.id)
      expect(results[1]['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')

      expect(results[2]['owner_id']).to be_nil
      expect(results[2]['owner_type']).to eq('GrdaWarehouse::Hud::Client')
    end

    it 'handles individual lookups' do
      # Process records individually (simulates non-batch mode)
      results = source_records.map do |source_record|
        mapped_attributes = {}
        HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(
          source_record,
          mapped_attributes,
          columns,
        )
        mapped_attributes
      end

      # Verify results are the same as batch processing
      expect(results[0]['owner_id']).to eq(test_client.id)
      expect(results[0]['owner_type']).to eq('GrdaWarehouse::Hud::Client')

      expect(results[1]['owner_id']).to eq(test_enrollment.id)
      expect(results[1]['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')

      expect(results[2]['owner_id']).to be_nil
      expect(results[2]['owner_type']).to eq('GrdaWarehouse::Hud::Client')
    end
  end

  describe 'CustomDataElement importer class' do
    let(:custom_importer_class) { HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement }

    it 'exists and is properly configured' do
      expect(custom_importer_class).to be_a(Class)
      expect(custom_importer_class.included_modules).to include(HmisCsvTwentyTwentySix::Importer::Custom::CustomImportConcern)
    end

    it 'has correct upsert_column_names' do
      column_names = custom_importer_class.upsert_column_names(version: '2026')

      expect(column_names).to include(:CustomDataElementID)
      expect(column_names).to include(:CustomDataElementDefinitionID)
      expect(column_names).to include(:owner_type)
      expect(column_names).to include(:owner_id)
      expect(column_names).to include(:Value)
      expect(column_names).to include(:UserID)

      # Should exclude the standard excluded columns
      expect(column_names).not_to include(:DateCreated)
      expect(column_names).not_to include(:DateUpdated)
      expect(column_names).not_to include(:DateDeleted)
      expect(column_names).not_to include(:ExportID)
    end
  end

  describe 'Configuration validation' do
    it 'has a valid configuration for CustomDataElement.csv' do
      expect(config).to be_present
      expect(config['filename']).to eq('CustomDataElement.csv')
      expect(config['class_name']).to eq('CustomDataElement')
      expect(config['columns']).to be_an(Array)
      expect(config['columns'].length).to be > 0
    end

    it 'has proper warehouse column mappings configured' do
      # Find RecordType column
      record_type_col = columns.find { |col| col['name'] == 'RecordType' }
      expect(record_type_col).to be_present
      expect(record_type_col['warehouse_column_mapping']).to be_present
      expect(record_type_col['warehouse_column_mapping']['type']).to eq('value_mapping')
      expect(record_type_col['warehouse_column_mapping']['target_column']).to eq('owner_type')
      expect(record_type_col['warehouse_column_mapping']['value_mappings']).to be_present

      # Find RecordID column
      record_id_col = columns.find { |col| col['name'] == 'RecordID' }
      expect(record_id_col).to be_present
      expect(record_id_col['warehouse_column_mapping']).to be_present
      expect(record_id_col['warehouse_column_mapping']['type']).to eq('record_lookup')
      expect(record_id_col['warehouse_column_mapping']['target_column']).to eq('owner_id')
      expect(record_id_col['warehouse_column_mapping']['lookup_field_mappings']).to be_present

      # Find UserID column (should have no explicit mapping)
      user_id_col = columns.find { |col| col['name'] == 'UserID' }
      expect(user_id_col).to be_present
      expect(user_id_col['warehouse_column_mapping']).to be_nil
    end
  end

  describe 'Performance considerations' do
    let!(:additional_clients) do
      (1..10).map do |i|
        create(:grda_warehouse_hud_client, data_source: data_source, PersonalID: "CLIENT#{i.to_s.rjust(3, '0')}")
      end
    end

    let(:large_record_set) do
      (1..10).map do |i|
        HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
          CustomDataElementID: "CDE#{i.to_s.rjust(3, '0')}",
          CustomDataElementDefinitionID: "DEF#{i.to_s.rjust(3, '0')}",
          RecordType: 'Client',
          RecordID: "CLIENT#{i.to_s.rjust(3, '0')}",
          Value: "value#{i}",
          UserID: "user#{i}",
          data_source_id: data_source.id,
          importer_log_id: importer_log.id,
        )
      end
    end

    it 'processes large batches efficiently without N+1 queries' do
      # Test batch processing - should use very few queries regardless of record count
      expect do
        results = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings_batch(
          large_record_set,
          columns,
        )

        # Verify we got results for all records
        expect(results.length).to eq(10)

        # Verify lookups were resolved correctly
        results.each_with_index do |result, index|
          expected_client = additional_clients[index]
          expect(result['owner_id']).to eq(expected_client.id)
          expect(result['owner_type']).to eq('GrdaWarehouse::Hud::Client')
        end
      end.to make_database_queries(count: 2..10) # Should be very few queries regardless of record count
    end

    it 'batch processing is more efficient than individual processing' do
      # First test individual processing to see how many queries it makes
      expect do
        large_record_set.each do |source_record|
          mapped_attributes = {}
          HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(
            source_record,
            mapped_attributes,
            columns,
          )
        end
      end.to make_database_queries(count: 10..50) # Individual processing should make more queries

      # Now test batch processing - should be much more efficient
      expect do
        HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings_batch(
          large_record_set,
          columns,
        )
      end.to make_database_queries(count: 1..5) # Batch should be much more efficient
    end

    it 'scales efficiently with larger datasets' do
      # Create an even larger dataset to test scalability
      large_client_set = (11..25).map do |i|
        create(:grda_warehouse_hud_client, data_source: data_source, PersonalID: "CLIENT#{i.to_s.rjust(3, '0')}")
      end

      larger_record_set = (11..25).map do |i|
        HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
          CustomDataElementID: "CDE#{i.to_s.rjust(3, '0')}",
          CustomDataElementDefinitionID: "DEF#{i.to_s.rjust(3, '0')}",
          RecordType: 'Client',
          RecordID: "CLIENT#{i.to_s.rjust(3, '0')}",
          Value: "value#{i}",
          UserID: "user#{i}",
          data_source_id: data_source.id,
          importer_log_id: importer_log.id,
        )
      end

      # Even with 15 records, query count should remain low and constant
      expect do
        results = HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings_batch(
          larger_record_set,
          columns,
        )

        expect(results.length).to eq(15)
        results.each_with_index do |result, index|
          expected_client = large_client_set[index]
          expect(result['owner_id']).to eq(expected_client.id)
          expect(result['owner_type']).to eq('GrdaWarehouse::Hud::Client')
        end
      end.to make_database_queries(count: 1..5) # Should still be very few queries even with more records
    end
  end

  describe 'Real-world scenario simulation' do
    let(:source_record) do
      HmisCsvTwentyTwentySix::Importer::Custom::CustomDataElement.new(
        CustomDataElementID: 'CDE789',
        CustomDataElementDefinitionID: 'DEF456',
        RecordType: 'Client',
        RecordID: 'CLIENT123',
        Value: 'Housing Status: Permanent',
        DataCollectionStage: 1,
        InformationDate: Date.parse('2024-01-15'),
        UserID: 'admin_user',
        DateCreated: DateTime.parse('2024-01-15T09:30:00Z'),
        DateUpdated: DateTime.parse('2024-01-15T09:30:00Z'),
        DateDeleted: nil,
        ExportID: 'exp789',
        data_source_id: data_source.id,
        importer_log_id: importer_log.id,
      )
    end

    it 'processes a complete CustomDataElement record as it would in production' do
      mapped_attributes = {}
      HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(source_record, mapped_attributes, columns)

      # Verify the complete transformation with flexible date matching
      expect(mapped_attributes['CustomDataElementID']).to eq('CDE789')
      expect(mapped_attributes['CustomDataElementDefinitionID']).to eq('DEF456')
      expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
      expect(mapped_attributes['owner_id']).to eq(test_client.id)
      expect(mapped_attributes['Value']).to eq('Housing Status: Permanent')
      expect(mapped_attributes['DataCollectionStage']).to eq(1)
      expect(mapped_attributes['UserID']).to eq('admin_user')
      expect(mapped_attributes['DateDeleted']).to be_nil
      expect(mapped_attributes['ExportID']).to eq('exp789')

      # Flexible date/time matching - allow Time/DateTime conversion
      expect(mapped_attributes['InformationDate']).to be_a_kind_of(Time)
      expect(mapped_attributes['InformationDate'].to_date.to_fs(:db)).to eq('2024-01-15')
      expect(mapped_attributes['DateCreated']).to be_a_kind_of(Time)
      expect(mapped_attributes['DateUpdated']).to be_a_kind_of(Time)
    end

    it 'handles edge cases correctly' do
      edge_cases = [
        {
          name: 'missing record ID',
          modify: ->(record) { record.RecordID = '' },
          expected_owner_id: nil,
        },
        {
          name: 'unknown record type',
          modify: ->(record) { record.RecordType = 'UnknownType' },
          expected_owner_id: nil,
        },
        {
          name: 'missing value',
          modify: ->(record) { record.Value = nil },
          expected_value: nil,
        },
      ]

      edge_cases.each do |test_case|
        test_record = source_record.dup
        test_case[:modify]&.call(test_record)

        mapped_attributes = {}
        HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper.apply_mappings(test_record, mapped_attributes, columns)

        expect(mapped_attributes['owner_id']).to eq(test_case[:expected_owner_id]) if test_case.key?(:expected_owner_id)

        expect(mapped_attributes['Value']).to eq(test_case[:expected_value]) if test_case.key?(:expected_value)
      end
    end
  end
end
