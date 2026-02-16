###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomDataElementDefinition, type: :model do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:user) { create(:hmis_hud_user, data_source: data_source) }

  describe 'reporting_key validations' do
    it 'allows nil reporting_key' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: nil,
      )
      expect(cded).to be_valid
    end

    it 'allows valid reporting_key (lowercase, starts with letter, max 63 chars)' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: 'valid_key_123',
      )
      expect(cded).to be_valid
    end

    it 'rejects reporting_key starting with number' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: '1invalid',
      )
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key with uppercase letters' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: 'InvalidKey',
      )
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key with special characters' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: 'invalid-key',
      )
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'rejects reporting_key longer than 63 characters' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: 'a' * 64,
      )
      expect(cded).not_to be_valid
      expect(cded.errors[:reporting_key]).to be_present
    end

    it 'allows reporting_key with exactly 63 characters' do
      cded = build(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        user: user,
        reporting_key: 'a' * 63,
      )
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

      # enforced in a DB constraint, not an AR validation
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
end
