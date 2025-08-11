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
            create(:hmis_custom_data_element_definition, key: "#{definition.identifier}_linkid_string", data_source: data_source, owner_type: 'Hmis::Hud::CustomAssessment')
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
end
