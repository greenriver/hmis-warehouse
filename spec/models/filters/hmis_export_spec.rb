###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filters::HmisExport, type: :model do
  let(:user) { create(:user) }
  let(:filter) { described_class.new(user_id: user.id) }

  describe 'attributes' do
    it 'has custom_file_types attribute with default empty array' do
      expect(filter.custom_file_types).to eq([])
    end

    it 'accepts custom_file_types as an array' do
      filter.custom_file_types = ['CustomGender', 'CustomSexualOrientation']
      expect(filter.custom_file_types).to eq(['CustomGender', 'CustomSexualOrientation'])
    end
  end

  describe '#update' do
    context 'with custom_file_types parameter' do
      it 'updates custom_file_types from filters hash' do
        filters = { custom_file_types: ['CustomGender', 'CustomSexualOrientation'] }
        filter.update(filters)
        expect(filter.custom_file_types).to eq(['CustomGender', 'CustomSexualOrientation'])
      end

      it 'handles empty custom_file_types array' do
        filters = { custom_file_types: [] }
        filter.update(filters)
        expect(filter.custom_file_types).to eq([])
      end

      it 'handles nil custom_file_types' do
        filters = { custom_file_types: nil }
        filter.update(filters)
        expect(filter.custom_file_types).to eq([])
      end

      it 'handles missing custom_file_types parameter' do
        filters = { version: '2026' }
        filter.update(filters)
        expect(filter.custom_file_types).to eq([])
      end

      it 'preserves other filter parameters when updating custom_file_types' do
        filters = {
          version: '2026',
          start_date: 1.year.ago.to_date,
          custom_file_types: ['CustomGender'],
        }
        filter.update(filters)
        expect(filter.version).to eq('2026')
        expect(filter.start_date).to eq(1.year.ago.to_date)
        expect(filter.custom_file_types).to eq(['CustomGender'])
      end
    end
  end

  describe '#for_params' do
    it 'includes custom_file_types in the parameters hash' do
      filter.custom_file_types = ['CustomGender', 'CustomSexualOrientation']
      params = filter.for_params
      expect(params[:filters][:custom_file_types]).to eq(['CustomGender', 'CustomSexualOrientation'])
    end

    it 'includes empty array when no custom files selected' do
      params = filter.for_params
      expect(params[:filters][:custom_file_types]).to eq([])
    end
  end

  describe '#available_custom_file_types' do
    context 'when version is 2026' do
      before { filter.version = '2026' }

      it 'returns available custom file types from configuration' do
        available_types = filter.available_custom_file_types
        expect(available_types).to be_a(Hash)
        # Should include the files from our test configuration
        expect(available_types.values).to include('CustomGender.csv', 'CustomSexualOrientation.csv')
      end
    end

    context 'when version is not 2026' do
      before { filter.version = '2024' }

      it 'returns empty array' do
        available_types = filter.available_custom_file_types
        expect(available_types).to eq({})
      end
    end

    context 'when version is nil' do
      before { filter.version = nil }

      it 'returns empty array' do
        available_types = filter.available_custom_file_types
        expect(available_types).to eq({})
      end
    end
  end

  describe '#valid_custom_file_types' do
    before { filter.version = '2026' }

    it 'returns intersection of selected and available custom file types' do
      filter.custom_file_types = ['CustomGender.csv', 'InvalidType', 'CustomSexualOrientation.csv']
      valid_types = filter.valid_custom_file_types
      expect(valid_types).to contain_exactly('CustomGender.csv', 'CustomSexualOrientation.csv')
    end

    it 'returns empty array when no custom files selected' do
      filter.custom_file_types = []
      valid_types = filter.valid_custom_file_types
      expect(valid_types).to eq([])
    end

    it 'returns empty array when selected types are not available' do
      filter.custom_file_types = ['InvalidType1', 'InvalidType2']
      valid_types = filter.valid_custom_file_types
      expect(valid_types).to eq([])
    end
  end

  describe 'integration with existing filter functionality' do
    it 'maintains all existing validations' do
      filter.start_date = nil
      filter.end_date = nil
      expect(filter).not_to be_valid
      expect(filter.errors[:start_date]).to include("can't be blank")
      expect(filter.errors[:end_date]).to include("can't be blank")
    end

    it 'validates date order with custom files' do
      filter.start_date = Date.current
      filter.end_date = 1.day.ago.to_date
      filter.custom_file_types = ['CustomGender.csv']
      expect(filter).not_to be_valid
      expect(filter.errors[:end_date]).to include('must follow start date')
    end

    it 'is valid with proper dates and custom files' do
      filter.start_date = 1.year.ago.to_date
      filter.end_date = Date.current
      filter.version = '2026'
      filter.custom_file_types = ['CustomGender.csv']
      expect(filter).to be_valid
    end
  end

  describe 'version compatibility' do
    it 'allows custom_file_types for FY2026' do
      filter.version = '2026'
      filter.custom_file_types = ['CustomGender.csv']
      available_types = filter.available_custom_file_types
      expect(available_types).not_to be_empty
    end

    it 'returns empty available types for older versions' do
      filter.version = '2024'
      filter.custom_file_types = ['CustomGender.csv'] # This should be allowed but ignored
      available_types = filter.available_custom_file_types
      expect(available_types).to be_empty
    end

    it 'gracefully handles version switching' do
      # Start with 2026
      filter.version = '2026'
      filter.custom_file_types = ['CustomGender.csv']
      expect(filter.available_custom_file_types).not_to be_empty

      # Switch to 2024
      filter.version = '2024'
      expect(filter.available_custom_file_types).to be_empty
      expect(filter.custom_file_types).to eq(['CustomGender.csv']) # Still stored
      expect(filter.valid_custom_file_types).to be_empty # But not valid
    end
  end
end
