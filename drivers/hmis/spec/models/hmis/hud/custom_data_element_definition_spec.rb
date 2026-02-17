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

  describe 'reporting_key validations' do
    it 'allows nil reporting_key' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: nil)
      expect(cded).to be_valid
    end

    it 'allows valid reporting_key (lowercase, starts with letter, max 63 chars)' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: 'valid_key_123')
      expect(cded).to be_valid
    end

    it 'rejects reporting_key starting with number' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: '1invalid')
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key with uppercase letters' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: 'InvalidKey')
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key with special characters' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: 'invalid-key')
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key longer than 63 characters' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: 'a' * 64)
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'allows reporting_key with exactly 63 characters' do
      cded = build(:hmis_custom_data_element_definition, reporting_key: 'a' * 63)
      expect(cded).to be_valid
    end

    it 'enforces uniqueness scoped to owner_type' do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: 'Hmis::Hud::Client',
        reporting_key: 'duplicate_key',
      )

      duplicate = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: 'Hmis::Hud::Client',
        reporting_key: 'duplicate_key',
      )

      # enforced in a DB constraint, not an AR validation, so check for ActiveRecord::StatementInvalid
      expect do
        duplicate.save!
      end.to raise_error(ActiveRecord::StatementInvalid, /violates unique constraint/).
        and not_change(Hmis::Hud::CustomDataElementDefinition, :count).from(1)
    end

    it 'allows same reporting_key for different owner_types' do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: 'Hmis::Hud::Client',
        reporting_key: 'shared_key',
      )

      different_owner = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        owner_type: 'Hmis::Hud::Service',
        reporting_key: 'shared_key',
      )

      expect(different_owner).to be_valid
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
