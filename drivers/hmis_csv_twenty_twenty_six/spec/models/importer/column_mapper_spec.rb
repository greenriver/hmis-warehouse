###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Importer::Custom::ColumnMapper do
  describe '.apply_mappings' do
    let(:mapped_attributes) { {} }

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

      it 'maps Client to GrdaWarehouse::Hud::Client' do
        source_record = { 'RecordType' => 'Client' }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
      end

      it 'maps Enrollment to GrdaWarehouse::Hud::Enrollment' do
        source_record = { 'RecordType' => 'Enrollment' }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Enrollment')
      end

      it 'leaves unmapped values as-is' do
        source_record = { 'RecordType' => 'UnknownType' }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['owner_type']).to eq('UnknownType')
      end

      it 'handles nil values' do
        source_record = { 'RecordType' => nil }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
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

      it 'maps Label to label with direct mapping' do
        source_record = { 'Label' => 'Assessment Type' }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['label']).to eq('Assessment Type')
      end

      it 'handles nil values in direct mapping' do
        source_record = { 'Label' => nil }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
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

      it 'uses column name as target_column when no mapping is specified' do
        source_record = { 'UserID' => 'user123' }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['UserID']).to eq('user123')
      end

      it 'handles nil values with default mapping' do
        source_record = { 'UserID' => nil }
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
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

      it 'handles all mapping types correctly' do
        source_record = {
          'RecordType' => 'Enrollment',
          'Label' => 'Assessment Type',
          'Key' => 'assessment_type',
          'FieldType' => 'string',
          'Repeats' => 'false',
          'UserID' => 'user456',
          'DateCreated' => '2024-01-01T10:00:00Z',
        }

        described_class.apply_mappings(source_record, mapped_attributes, column_configs)

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

      it 'handles missing source columns gracefully' do
        source_record = { 'RecordType' => 'Client' }
        # Missing 'Label' key in source_record
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)

        expect(mapped_attributes['owner_type']).to eq('GrdaWarehouse::Hud::Client')
        expect(mapped_attributes['label']).to be_nil
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

      it 'applies defaults (direct mapping with same column name)' do
        source_record = { 'TestColumn' => 'test_value' }
        mapped_attributes = {}
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['TestColumn']).to eq('test_value')
      end

      it 'handles nil values with default behavior' do
        source_record = { 'TestColumn' => nil }
        mapped_attributes = {}
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
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

      it 'applies defaults for missing configuration' do
        source_record = { 'TestColumn' => 'A' }
        mapped_attributes = {}
        described_class.apply_mappings(source_record, mapped_attributes, column_configs)
        expect(mapped_attributes['TestColumn']).to eq('Alpha')
      end
    end
  end
end
