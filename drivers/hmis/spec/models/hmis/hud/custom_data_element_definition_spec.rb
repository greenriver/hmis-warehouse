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
end
