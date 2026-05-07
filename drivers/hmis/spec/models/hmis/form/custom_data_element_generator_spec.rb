# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Form::CustomDataElementGenerator, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:definition_json) do
    {
      'item': [
        {
          'type': 'STRING',
          'link_id': 'linkid_string',
          'required': false,
          'text': 'String Field',
          'assessment_date': true,
        },
      ],
    }
  end
  let(:definition) { create(:hmis_form_definition, definition: definition_json) }

  describe '#run' do
    context 'when the definition has an unmapped item' do
      let(:definition_json) do
        {
          'item': [
            {
              'type': 'STRING',
              'link_id': 'linkid_string',
              'required': false,
              'text': 'String Field',
              'assessment_date': true,
            },
          ],
        }
      end

      context 'when create_missing_mappings is true' do
        it 'creates new CDEDs for unmapped items and updates the definition' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          cdeds = generator.run
          added_key = definition.definition.dig('item', 0, 'mapping', 'custom_field_key')
          expect(definition.changed?).to be_truthy
          expect(cdeds).not_to be_empty
          expect(added_key).to be_present
          expect(cdeds.sole).to have_attributes(
            key: added_key,
            label: 'String Field',
            field_type: 'string',
            repeats: false,
            owner_type: 'Hmis::Hud::CustomAssessment',
            form_definition_identifier: definition.identifier,
            data_source: data_source,
          )
        end

        context 'when a CDED with the generated key already exists' do
          before do
            create(:hmis_custom_data_element_definition, key: 'linkid_string', data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment')
          end
          it 'generates a unique key for the new CDED' do
            generator = described_class.new(
              definition: definition,
              create_missing_mappings: true,
              data_source: data_source,
            )
            cdeds = generator.run
            added_key = definition.definition.dig('item', 0, 'mapping', 'custom_field_key')
            expect(definition.changed?).to be_truthy
            expect(added_key).to match(/_2$/)
            expect(cdeds).not_to be_empty
            expect(cdeds.sole.key).to eq(added_key)
          end
        end

        it 'generates valid reporting_key for new CDEDs' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          cdeds = generator.run
          expect(cdeds.sole.reporting_key).to be_present
          expect(cdeds.sole.reporting_key).to eq(cdeds.sole.key)
        end
      end

      context 'when create_missing_mappings is false' do
        it 'does not create new CDEDs for unmapped items' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: false,
            data_source: data_source,
          )

          cdeds = generator.run
          expect(cdeds).to be_empty
          expect(definition.changed?).to be_falsey
        end
      end
    end

    context 'when the definition has a mapped item' do
      let(:cded_key) { 'use_this_key' }
      let(:definition_json) do
        {
          'item': [
            {
              'type': 'STRING',
              'link_id': 'linkid_string',
              'required': false,
              'text': 'String Field',
              'assessment_date': true,
              'mapping': { 'custom_field_key': cded_key },
            },
          ],
        }
      end

      it 'creates a new CDED for the item, using the specified key' do
        generator = described_class.new(
          definition: definition,
          create_missing_mappings: true,
          data_source: data_source,
        )

        cdeds = generator.run
        added_key = definition.definition.dig('item', 0, 'mapping', 'custom_field_key')
        expect(definition.changed?).to be_falsey
        expect(cdeds).not_to be_empty
        expect(added_key).to be_present
        expect(cdeds.sole).to have_attributes(
          key: cded_key,
          label: 'String Field',
          field_type: 'string',
          repeats: false,
          owner_type: 'Hmis::Hud::CustomAssessment',
          form_definition_identifier: definition.identifier,
          data_source: data_source,
        )
      end

      context 'and the CDED already exists' do
        before do
          create(:hmis_custom_data_element_definition, key: cded_key, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: definition.identifier, label: 'String Field')
        end

        it 'does not create a new CDED' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          cdeds = generator.run
          expect(definition.changed?).to be_falsey
          expect(cdeds).to be_empty
        end
      end

      context 'and the CDED already exists, but the label has changed' do
        let!(:existing_cded) do
          create(:hmis_custom_data_element_definition, key: cded_key, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: definition.identifier, label: 'Previous Label')
        end

        it 'updates the CDED label' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          cdeds = generator.run
          expect(definition.changed?).to be_falsey
          expect(cdeds.sole).to have_attributes(
            key: cded_key,
            id: existing_cded.id,
            label: 'String Field',
            field_type: 'string',
            repeats: false,
            owner_type: 'Hmis::Hud::CustomAssessment',
            form_definition_identifier: definition.identifier,
            data_source: data_source,
          )
        end
      end

      context 'and the CDED already exists, but is tied to a different form' do
        let!(:existing_cded) do
          create(:hmis_custom_data_element_definition, key: cded_key, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: 'another_form', label: 'String Field')
        end

        it 'raises an error' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          expect { generator.run }.to raise_error(/references a CDED .* belongs to a different form/)
        end
      end

      context 'and the CDED exists but has the wrong type' do
        let!(:existing_cded) do
          create(:hmis_custom_data_element_definition, key: cded_key, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: definition.identifier, label: 'String Field', field_type: 'integer')
        end

        it 'raises an error' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          expect { generator.run }.to raise_error(/incompatible type/)
        end
      end

      context 'and the CDED exists but has a mismatch in "repeats" value' do
        let!(:existing_cded) do
          create(:hmis_custom_data_element_definition, key: cded_key, data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: definition.identifier, label: 'String Field', repeats: true)
        end

        it 'raises an error' do
          generator = described_class.new(
            definition: definition,
            create_missing_mappings: true,
            data_source: data_source,
          )

          expect { generator.run }.to raise_error(/repeats mismatch/)
        end
      end
    end
  end

  describe '.generate_reporting_key' do
    let(:owner_type) { 'Hmis::Hud::CustomAssessment' }
    let(:user) { create(:hmis_hud_user, data_source: data_source) }

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
      create(:hmis_custom_data_element_definition, data_source: data_source, user: user, owner_type: owner_type, reporting_key: 'duplicate_key')

      key = described_class.generate_reporting_key('duplicate_key', owner_type: owner_type)
      expect(key).to eq('duplicate_key_1')
    end

    it 'appends number when reporting_key conflicts with unpersisted reserved keys' do
      reserved_keys = Set.new([[owner_type, 'reserved_key']])
      key = described_class.generate_reporting_key('reserved_key', owner_type: owner_type, unpersisted_reserved_keys: reserved_keys)
      expect(key).to eq('reserved_key_1')
    end

    it 'truncates and appends number for long conflicting keys' do
      create(:hmis_custom_data_element_definition, data_source: data_source, user: user, owner_type: owner_type, reporting_key: 'a' * 63)

      key = described_class.generate_reporting_key('a' * 100, owner_type: owner_type)
      expect(key.length).to eq(63)
      expect(key).to end_with('_1')
    end

    it 'allows same reporting_key for different owner_types' do
      create(:hmis_custom_data_element_definition, data_source: data_source, user: user, owner_type: owner_type, reporting_key: 'shared_key')

      key = described_class.generate_reporting_key('shared_key', owner_type: 'Hmis::Hud::Service')
      expect(key).to eq('shared_key')
    end

    it 'raises error after 50 attempts' do
      51.times do |i|
        suffix = i.zero? ? '' : "_#{i}"
        create(:hmis_custom_data_element_definition, data_source: data_source, user: user, owner_type: owner_type, reporting_key: "key#{suffix}")
      end

      expect do
        described_class.generate_reporting_key('key', owner_type: owner_type)
      end.to raise_error(/Unique reporting_key generation failed/)
    end
  end
end
