###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomDataElementDefinition, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }
  let(:user) { create(:hmis_hud_user, data_source: data_source) }

  describe '.pick_list_labels_from_metadata' do
    it 'maps inline pick_list_options to a code => label hash' do
      metadata = {
        item_type: 'CHOICE',
        pick_list_reference: nil,
        pick_list_options: [
          { 'code' => 'hmis_user_error', 'label' => 'HMIS user error' },
          { 'code' => 'client_declined', 'label' => 'Client declined' },
        ],
      }
      expect(described_class.pick_list_labels_from_metadata(metadata, user: user)).to eq(
        'hmis_user_error' => 'HMIS user error',
        'client_declined' => 'Client declined',
      )
    end

    it 'resolves static enum references' do
      metadata = { item_type: 'CHOICE', pick_list_reference: 'PRIOR_LIVING_SITUATION', pick_list_options: nil }
      labels = described_class.pick_list_labels_from_metadata(metadata, user: user)
      expect(labels).not_to be_empty
      expect(labels.values).to all(be_a(String))
    end

    it 'returns {} for dynamic references that need context' do
      metadata = { item_type: 'CHOICE', pick_list_reference: 'PROJECT', pick_list_options: nil }
      expect(described_class.pick_list_labels_from_metadata(metadata, user: user)).to eq({})
    end

    it 'returns {} for blank metadata or non-choice items' do
      expect(described_class.pick_list_labels_from_metadata(nil, user: user)).to eq({})
      expect(described_class.pick_list_labels_from_metadata({}, user: user)).to eq({})
      expect(described_class.pick_list_labels_from_metadata({ item_type: 'STRING' }, user: user)).to eq({})
    end
  end

  describe '#pick_list_labels' do
    let!(:form_definition) do
      create(:hmis_form_definition, data_source: data_source, role: :CUSTOM_ASSESSMENT, identifier: 'labels-form', append_items: [
               {
                 'type' => 'CHOICE',
                 'link_id' => 'decision',
                 'text' => 'Decision',
                 'mapping' => { 'custom_field_key' => 'decision' },
                 'pick_list_options' => [
                   { 'code' => 'hmis_user_error', 'label' => 'HMIS user error' },
                 ],
               },
             ])
    end

    it 'resolves labels via published/retired form definition versions' do
      cded = create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'decision', form_definition_identifier: 'labels-form')
      expect(cded.pick_list_labels(user: user)).to eq('hmis_user_error' => 'HMIS user error')
    end

    it 'returns {} when there is no associated form definition' do
      cded = create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', key: 'decision', form_definition_identifier: nil)
      expect(cded.pick_list_labels(user: user)).to eq({})
    end
  end

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
