###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomDataElementDefinition, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }
  let(:user) { create(:hmis_hud_user, data_source: data_source) }

  shared_examples 'saves successfully' do
    it 'is valid and saves' do
      expect(subject).to be_valid
      expect { subject.save! }.to change(Hmis::Hud::CustomDataElementDefinition, :count).by(1)
    end
  end

  shared_examples 'rejects with error' do |error_pattern|
    it 'raises an error and does not save' do
      expect do
        subject.save!
      end.to raise_error(ActiveRecord::StatementInvalid, error_pattern).
        and not_change(Hmis::Hud::CustomDataElementDefinition, :count)
    end
  end

  describe 'reporting_key validations' do
    context 'allows nil reporting_key' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: nil) }
      include_examples 'saves successfully'
    end

    context 'allows valid reporting_key (lowercase, starts with letter, max 63 chars)' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: 'valid_key_123') }
      include_examples 'saves successfully'
    end

    context 'allows reporting_key with exactly 63 characters' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: 'a' * 63) }
      include_examples 'saves successfully'
    end

    context 'rejects reporting_key starting with number' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: '1invalid') }
      include_examples 'rejects with error', /violates check constraint/
    end

    context 'rejects reporting_key with uppercase letters' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: 'InvalidKey') }
      include_examples 'rejects with error', /violates check constraint/
    end

    context 'rejects reporting_key with special characters' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: 'invalid-key') }
      include_examples 'rejects with error', /violates check constraint/
    end

    context 'rejects reporting_key longer than 63 characters' do
      subject { build(:hmis_custom_data_element_definition, reporting_key: 'a' * 64) }
      include_examples 'rejects with error', /value too long/
    end

    context 'enforces uniqueness scoped to owner_type' do
      before do
        create(
          :hmis_custom_data_element_definition,
          data_source: data_source,
          user: user,
          owner_type: 'Hmis::Hud::Client',
          reporting_key: 'duplicate_key',
        )
      end

      subject do
        build(
          :hmis_custom_data_element_definition,
          data_source: data_source,
          user: user,
          owner_type: 'Hmis::Hud::Client',
          reporting_key: 'duplicate_key',
        )
      end

      include_examples 'rejects with error', /violates unique constraint/
    end

    context 'allows same reporting_key for different owner_types' do
      before do
        create(
          :hmis_custom_data_element_definition,
          data_source: data_source,
          user: user,
          owner_type: 'Hmis::Hud::Client',
          reporting_key: 'shared_key',
        )
      end

      subject do
        build(
          :hmis_custom_data_element_definition,
          data_source: data_source,
          user: user,
          owner_type: 'Hmis::Hud::Service',
          reporting_key: 'shared_key',
        )
      end

      include_examples 'saves successfully'
    end
  end

  describe '.generate_reporting_key' do
    let(:owner_type) { 'Hmis::Hud::CustomAssessment' }

    it 'generates valid reporting_key from lowercase key with underscores' do
      key = described_class.generate_reporting_key('valid_key', owner_type: owner_type)
      expect(key).to eq('valid_key')
      expect(key).to match(/\A[a-z][a-z0-9_]{0,62}\z/)
    end

    it 'converts hyphens to underscores' do
      key = described_class.generate_reporting_key('key-with-hyphens', owner_type: owner_type)
      expect(key).to eq('key_with_hyphens')
    end

    it 'converts special characters to underscores' do
      key = described_class.generate_reporting_key('key$with@special!chars', owner_type: owner_type)
      expect(key).to eq('key_with_special_chars')
    end

    it 'prepends "k_" when key starts with a number' do
      key = described_class.generate_reporting_key('1invalid', owner_type: owner_type)
      expect(key).to eq('k_1invalid')
    end

    it 'truncates keys longer than 63 characters' do
      key = described_class.generate_reporting_key('a' * 100, owner_type: owner_type)
      expect(key.length).to eq(63)
      expect(key).to eq('a' * 63)
    end

    it 'appends number when reporting_key conflicts with existing record' do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: owner_type,
        reporting_key: 'duplicate_key',
      )

      key = described_class.generate_reporting_key('duplicate_key', owner_type: owner_type)
      expect(key).to eq('duplicate_key_1')
    end

    it 'appends number when reporting_key conflicts with unpersisted reserved keys' do
      reserved_keys = Set.new([[owner_type, 'reserved_key']])
      key = described_class.generate_reporting_key('reserved_key', owner_type: owner_type, unpersisted_reserved_keys: reserved_keys)
      expect(key).to eq('reserved_key_1')
    end

    it 'truncates and appends number for long conflicting keys' do
      long_key = 'a' * 63
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: owner_type,
        reporting_key: long_key,
      )

      key = described_class.generate_reporting_key('a' * 100, owner_type: owner_type)
      expect(key.length).to eq(63)
      expect(key).to end_with('_1')
    end

    it 'allows same reporting_key for different owner_types' do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: owner_type,
        reporting_key: 'shared_key',
      )

      # Different owner_type should not conflict
      key = described_class.generate_reporting_key('shared_key', owner_type: 'Hmis::Hud::Service')
      expect(key).to eq('shared_key')
    end

    it 'raises error after 50 attempts' do
      # Create 51 records with conflicting keys
      51.times do |i|
        suffix = i.zero? ? '' : "_#{i}"
        create(
          :hmis_custom_data_element_definition,
          data_source: data_source,
          user: user,
          owner_type: owner_type,
          reporting_key: "key#{suffix}",
        )
      end

      expect do
        described_class.generate_reporting_key('key', owner_type: owner_type)
      end.to raise_error(/Unique reporting_key generation failed/)
    end
  end
end
