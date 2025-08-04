###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper do
  let(:source_record_class) do
    Class.new(OpenStruct) do
      def self.hud_key
        'test_id'
      end

      # ColumnMapper needs `[]` to access source values.
      def [](key)
        public_send(key)
      end
    end
  end
  describe '#map' do
    context 'with value_mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'RecordType',
            'warehouse_column_mapping' => {
              'type' => 'value_mapping',
              'target_column' => 'owner_type',
              'value_mappings' => {
                'Client' => 'GrdaWarehouse::Hud::Client',
                'Enrollment' => 'GrdaWarehouse::Hud::Enrollment',
                'Exit' => 'GrdaWarehouse::Hud::Exit',
                'Project' => 'GrdaWarehouse::Hud::Project',
                'Organization' => 'GrdaWarehouse::Hud::Organization',
              },
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'maps Client to GrdaWarehouse::Hud::Client' do
        source_record = source_record_class.new(test_id: 1, RecordType: 'Client')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
      end

      it 'maps Enrollment to GrdaWarehouse::Hud::Enrollment' do
        source_record = source_record_class.new(test_id: 2, RecordType: 'Enrollment')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')
      end

      it 'leaves unmapped values as-is' do
        source_record = source_record_class.new(test_id: 3, RecordType: 'UnknownType')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['owner_type']).to eq('UnknownType')
      end

      it 'handles nil values' do
        source_record = source_record_class.new(test_id: 4, RecordType: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['owner_type']).to be_nil
      end
    end

    context 'with direct mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'Label',
            'warehouse_column_mapping' => {
              'type' => 'direct',
              'target_column' => 'label',
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'maps Label to label with direct mapping' do
        source_record = source_record_class.new(test_id: 1, Label: 'Assessment Type')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['label']).to eq('Assessment Type')
      end

      it 'handles nil values in direct mapping' do
        source_record = source_record_class.new(test_id: 2, Label: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['label']).to be_nil
      end
    end

    context 'with default mapping behavior' do
      let(:column_configs) do
        [
          {
            'name' => 'UserID',
            # No warehouse_column_mapping - should use defaults
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'uses column name as target_column when no mapping is specified' do
        source_record = source_record_class.new(test_id: 1, UserID: 'user123')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['UserID']).to eq('user123')
      end

      it 'handles nil values with default mapping' do
        source_record = source_record_class.new(test_id: 2, UserID: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['UserID']).to be_nil
      end
    end

    context 'with mixed mapping types' do
      let(:column_configs) do
        [
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
            'name' => 'UserID',
            # No mapping - should use defaults
          },
          {
            'name' => 'DateCreated',
            # No mapping - should use defaults
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'handles all mapping types correctly' do
        source_record = source_record_class.new(
          test_id: 1,
          'RecordType' => 'Enrollment',
          'Label' => 'Assessment Type',
          'Key' => 'assessment_type',
          'FieldType' => 'string',
          'Repeats' => 'false',
          'UserID' => 'user456',
          'DateCreated' => '2024-01-01T10:00:00Z',
        )

        mapped_attributes = mapper.map(source_record)

        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')
        expect(mapped_attributes['label']).to eq('Assessment Type')
        expect(mapped_attributes['key']).to eq('assessment_type')
        expect(mapped_attributes['field_type']).to eq('string')
        expect(mapped_attributes['repeats']).to eq('false')
        expect(mapped_attributes['UserID']).to eq('user456')
        expect(mapped_attributes['DateCreated']).to eq('2024-01-01T10:00:00Z')
      end
    end

    context 'with missing source data' do
      let(:column_configs) do
        [
          {
            'name' => 'RecordType',
            'warehouse_column_mapping' => {
              'type' => 'value_mapping',
              'target_column' => 'owner_type',
              'value_mappings' => {
                'Client' => 'GrdaWarehouse::Hud::Client',
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
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'handles missing source columns gracefully' do
        source_record = source_record_class.new(test_id: 1, RecordType: 'Client')
        # Missing 'Label' key in source_record
        mapped_attributes = mapper.map(source_record)

        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
        expect(mapped_attributes['label']).to be_nil
      end
    end
  end

  describe '#map' do
    context 'with concatenation mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'FirstName',
            'warehouse_column_mapping' => {
              'type' => 'concatenation',
              'target_column' => 'full_name',
              'separator' => ' ',
            },
          },
          {
            'name' => 'LastName',
            'warehouse_column_mapping' => {
              'type' => 'concatenation',
              'target_column' => 'full_name',
              'separator' => ' ',
            },
          },
          {
            'name' => 'MiddleInitial',
            'warehouse_column_mapping' => {
              'type' => 'concatenation',
              'target_column' => 'full_name',
              'separator' => ' ',
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'concatenates multiple values with separator' do
        source_record = source_record_class.new(
          test_id: 1,
          FirstName: 'John',
          LastName: 'Doe',
          MiddleInitial: 'A',
        )
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['full_name']).to eq('John Doe A')
      end

      it 'handles nil values in concatenation' do
        source_record = source_record_class.new(
          test_id: 2,
          FirstName: 'Jane',
          LastName: nil,
          MiddleInitial: 'B',
        )
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['full_name']).to eq('Jane B')
      end

      it 'uses default separator when not specified' do
        column_configs_without_separator = [
          {
            'name' => 'FirstName',
            'warehouse_column_mapping' => {
              'type' => 'concatenation',
              'target_column' => 'full_name',
            },
          },
          {
            'name' => 'LastName',
            'warehouse_column_mapping' => {
              'type' => 'concatenation',
              'target_column' => 'full_name',
            },
          },
        ]
        mapper_without_separator = described_class.new(column_configs_without_separator)

        source_record = source_record_class.new(
          test_id: 3,
          FirstName: 'Bob',
          LastName: 'Smith',
        )
        mapped_attributes = mapper_without_separator.map(source_record)
        expect(mapped_attributes['full_name']).to eq('Bob Smith')
      end

      it 'handles empty string values' do
        source_record = source_record_class.new(
          test_id: 4,
          FirstName: 'Alice',
          LastName: '',
          MiddleInitial: 'C',
        )
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['full_name']).to eq('Alice C')
      end
    end

    context 'with static_value mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'CreatedBy',
            'type' => 'string',
            'warehouse_column_mapping' => {
              'type' => 'static_value',
              'target_column' => 'created_by',
              'value' => 'system_import',
            },
          },
          {
            'name' => 'IsActive',
            'type' => 'boolean',
            'warehouse_column_mapping' => {
              'type' => 'static_value',
              'target_column' => 'is_active',
              'value' => true,
            },
          },
          {
            'name' => 'Priority',
            'type' => 'integer',
            'warehouse_column_mapping' => {
              'type' => 'static_value',
              'target_column' => 'priority',
              'value' => 1,
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'assigns static string values' do
        source_record = source_record_class.new(test_id: 1)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['created_by']).to eq('system_import')
      end

      it 'assigns static boolean values' do
        source_record = source_record_class.new(test_id: 2)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['is_active']).to eq(true)
      end

      it 'assigns static integer values' do
        source_record = source_record_class.new(test_id: 3)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['priority']).to eq(1)
      end

      it 'ignores source record values for static mappings' do
        source_record = source_record_class.new(
          test_id: 4,
          CreatedBy: 'user123',
          IsActive: false,
          Priority: 5,
        )
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['created_by']).to eq('system_import')
        expect(mapped_attributes['is_active']).to eq(true)
        expect(mapped_attributes['priority']).to eq(1)
      end
    end

    context 'with value_based_multi_column mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'Gender',
            'warehouse_column_mapping' => {
              'type' => 'value_based_multi_column',
              'value_mappings' => [
                {
                  'condition' => { 'value' => '1' },
                  'target_column' => 'Woman',
                  'target_value' => 1,
                },
                {
                  'condition' => { 'value' => '2' },
                  'target_column' => 'Man',
                  'target_value' => 1,
                },
                {
                  'condition' => { 'value' => '3' },
                  'target_column' => 'Transgender',
                  'target_value' => 1,
                },
                {
                  'condition' => { 'value' => '4' },
                  'target_column' => 'NonBinary',
                  'target_value' => 1,
                },
              ],
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'maps value 1 to Woman column' do
        source_record = source_record_class.new(test_id: 1, Gender: '1')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to eq(1)
        expect(mapped_attributes['Man']).to be_nil
        expect(mapped_attributes['Transgender']).to be_nil
        expect(mapped_attributes['NonBinary']).to be_nil
      end

      it 'maps value 2 to Man column' do
        source_record = source_record_class.new(test_id: 2, Gender: '2')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to be_nil
        expect(mapped_attributes['Man']).to eq(1)
        expect(mapped_attributes['Transgender']).to be_nil
        expect(mapped_attributes['NonBinary']).to be_nil
      end

      it 'maps value 3 to Transgender column' do
        source_record = source_record_class.new(test_id: 3, Gender: '3')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to be_nil
        expect(mapped_attributes['Man']).to be_nil
        expect(mapped_attributes['Transgender']).to eq(1)
        expect(mapped_attributes['NonBinary']).to be_nil
      end

      it 'maps value 4 to NonBinary column' do
        source_record = source_record_class.new(test_id: 4, Gender: '4')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to be_nil
        expect(mapped_attributes['Man']).to be_nil
        expect(mapped_attributes['Transgender']).to be_nil
        expect(mapped_attributes['NonBinary']).to eq(1)
      end

      it 'handles unmapped values' do
        source_record = source_record_class.new(test_id: 5, Gender: '99')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to be_nil
        expect(mapped_attributes['Man']).to be_nil
        expect(mapped_attributes['Transgender']).to be_nil
        expect(mapped_attributes['NonBinary']).to be_nil
      end

      it 'handles nil values' do
        source_record = source_record_class.new(test_id: 6, Gender: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['Woman']).to be_nil
        expect(mapped_attributes['Man']).to be_nil
        expect(mapped_attributes['Transgender']).to be_nil
        expect(mapped_attributes['NonBinary']).to be_nil
      end
    end

    context 'with record_lookup mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'ClientID',
            'warehouse_column_mapping' => {
              'type' => 'record_lookup',
              'class_column' => 'owner_type',
              'target_column' => 'owner_id',
              'lookup_field_mappings' => {
                'GrdaWarehouse::Hud::Client' => 'PersonalID',
                'GrdaWarehouse::Hud::Enrollment' => 'EnrollmentID',
              },
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }
      let(:data_source) { create(:grda_warehouse_data_source) }

      before do
        # Create test records for lookup
        @client = create(:hud_client, PersonalID: 'CLIENT001', data_source: data_source)
        @enrollment = create(:hud_enrollment, EnrollmentID: 'ENROLL001', data_source: data_source)
      end

      it 'skips record lookups in standard mappings phase' do
        source_record = source_record_class.new(
          test_id: 1,
          ClientID: 'CLIENT001',
          data_source_id: data_source.id,
        )

        # Record lookups are handled in batch phase, so they should be skipped in standard mappings
        mapped_attributes = {}
        mapper.send(:apply_standard_mappings, source_record, mapped_attributes)

        # Should not have processed the record_lookup mapping in standard phase
        expect(mapped_attributes['owner_id']).to be_nil
      end

      it 'handles record lookup configuration correctly' do
        # Test that the mapper correctly identifies record_lookup configs
        expect(mapper.instance_variable_get(:@record_lookup_configs).length).to eq(1)
        expect(mapper.instance_variable_get(:@record_lookup_configs).first['name']).to eq('ClientID')
      end

      it 'processes record lookups in batch mode' do
        source_record = source_record_class.new(
          test_id: 1,
          ClientID: 'CLIENT001',
          data_source_id: data_source.id,
        )

        # Mock the standard mappings to set owner_type
        allow(mapper).to receive(:apply_standard_mappings) do |_record, attributes|
          attributes['owner_type'] = 'GrdaWarehouse::Hud::Client'
        end

        # Test the batch processing
        results = [{ source_record: source_record, mapped_attributes: { 'owner_type' => 'GrdaWarehouse::Hud::Client' } }]
        mapper.send(:apply_record_lookups_batch, results)

        expect(results.first[:mapped_attributes]['owner_id']).to eq(@client.id)
      end

      it 'handles missing lookup records in batch mode' do
        source_record = source_record_class.new(
          test_id: 2,
          ClientID: 'MISSING001',
          data_source_id: data_source.id,
        )

        # Test the batch processing with missing record
        results = [{ source_record: source_record, mapped_attributes: { 'owner_type' => 'GrdaWarehouse::Hud::Client' } }]

        expect(Rails.logger).to receive(:warn).with(/Record lookup failed/)
        mapper.send(:apply_record_lookups_batch, results)

        expect(results.first[:mapped_attributes]['owner_id']).to be_nil
      end
    end

    context 'with unknown mapping type' do
      let(:column_configs) do
        [
          {
            'name' => 'TestColumn',
            'warehouse_column_mapping' => {
              'type' => 'unknown_type',
              'target_column' => 'test_target',
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'logs warning and continues processing' do
        expect(Rails.logger).to receive(:warn).with('Unknown mapping type: unknown_type')

        source_record = source_record_class.new(test_id: 1, TestColumn: 'test_value')
        mapped_attributes = mapper.map(source_record)

        expect(mapped_attributes).to eq({})
      end
    end

    context 'with type casting' do
      let(:column_configs) do
        [
          {
            'name' => 'IntegerField',
            'type' => 'integer',
            'warehouse_column_mapping' => {
              'type' => 'direct',
              'target_column' => 'integer_field',
            },
          },
          {
            'name' => 'BooleanField',
            'type' => 'boolean',
            'warehouse_column_mapping' => {
              'type' => 'direct',
              'target_column' => 'boolean_field',
            },
          },
          {
            'name' => 'DateField',
            'type' => 'date',
            'warehouse_column_mapping' => {
              'type' => 'direct',
              'target_column' => 'date_field',
            },
          },
          {
            'name' => 'DateTimeField',
            'type' => 'datetime',
            'warehouse_column_mapping' => {
              'type' => 'direct',
              'target_column' => 'datetime_field',
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'casts integer values correctly' do
        source_record = source_record_class.new(test_id: 1, IntegerField: '123')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['integer_field']).to eq(123)
      end

      it 'casts boolean values correctly' do
        source_record = source_record_class.new(test_id: 2, BooleanField: 'true')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['boolean_field']).to eq(true)
      end

      it 'casts date values correctly' do
        source_record = source_record_class.new(test_id: 3, DateField: '2024-01-15')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['date_field']).to eq(Date.parse('2024-01-15'))
      end

      it 'casts datetime values correctly' do
        source_record = source_record_class.new(test_id: 4, DateTimeField: '2024-01-15T10:30:00Z')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['datetime_field']).to be_a(Time)
      end

      it 'handles false boolean values correctly' do
        source_record = source_record_class.new(test_id: 5, BooleanField: false)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['boolean_field']).to eq(false)
      end

      it 'handles blank values' do
        source_record = source_record_class.new(test_id: 6, IntegerField: '', BooleanField: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['integer_field']).to be_nil
        expect(mapped_attributes['boolean_field']).to be_nil
      end
    end
  end

  describe 'default mapping behavior integration' do
    context 'when no warehouse_column_mapping is provided' do
      let(:column_configs) do
        [
          {
            'name' => 'TestColumn',
            # No warehouse_column_mapping - should use defaults
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'applies defaults (direct mapping with same column name)' do
        source_record = source_record_class.new(test_id: 1, TestColumn: 'test_value')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['TestColumn']).to eq('test_value')
      end

      it 'handles nil values with default behavior' do
        source_record = source_record_class.new(test_id: 2, TestColumn: nil)
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['TestColumn']).to be_nil
      end
    end

    context 'when partial warehouse_column_mapping is provided' do
      let(:column_configs) do
        [
          {
            'name' => 'TestColumn',
            'warehouse_column_mapping' => {
              'type' => 'value_mapping',
              'value_mappings' => {
                'A' => 'Alpha',
                'B' => 'Beta',
              },
              # No target_column - should default to 'TestColumn'
            },
          },
        ]
      end
      let(:mapper) { described_class.new(column_configs) }

      it 'applies defaults for missing configuration' do
        source_record = source_record_class.new(test_id: 1, TestColumn: 'A')
        mapped_attributes = mapper.map(source_record)
        expect(mapped_attributes['TestColumn']).to eq('Alpha')
      end
    end
  end
end
