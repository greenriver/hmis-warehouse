###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::Definition, type: :model do
  describe 'Validating submitted form values against FormDefinition' do
    let!(:definition) { create :hmis_form_definition }
    let(:completed_values) do
      {
        linkid_date: '2023-02-15',
        linkid_required: 2,
        linkid_choice: 'foo',
      }
    end

    it 'should pass when all fields are filled in' do
      errors = definition.validate_form_values(completed_values.stringify_keys)

      expect(errors).to be_empty
    end

    context 'required item behavior' do
      [
        # [<value>, <should error if required>]
        [nil, true],
        ['', true],
        [[], true],
        ['DATA_NOT_COLLECTED', false], # DNC is a valid answer for a required field
        [0, false],
        ['value', false],
        [Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE, false], # hidden field should not generate an error
      ].each do |value, should_error|
        it "should #{should_error ? '' : 'not'} error on #{value.nil? ? 'nil' : value}" do
          errors = definition.validate_form_values({
            **completed_values,
            linkid_required: value,
          }.stringify_keys)

          if should_error
            expected_error = { type: :required, severity: :error, link_id: 'linkid_required', readable_attribute: 'The Required Field' }
            expect(errors.map(&:to_h)).to contain_exactly(a_hash_including(expected_error))
          else
            expect(errors).to be_empty, errors.map(&:to_h)
          end
        end
      end
    end

    context 'warn_if_empty item behavior' do
      [
        # [<value>, <should warn on  WARN_IF_EMPTY>]
        [nil, true],
        ['', true],
        [[], true],
        ['DATA_NOT_COLLECTED', true],
        [0, false],
        ['value', false],
        [Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE, false], # hidden field should not generate a warning
      ].each do |value, should_warn|
        it "should #{should_warn ? '' : 'not'} warn on #{value.nil? ? 'nil' : value}" do
          errors = definition.validate_form_values({
            **completed_values,
            linkid_choice: value,
          }.stringify_keys)

          if should_warn
            expected_error = { type: :data_not_collected, severity: :warning, link_id: 'linkid_choice', readable_attribute: 'Choice field' }
            expect(errors.map(&:to_h)).to contain_exactly(a_hash_including(expected_error))
          else
            expect(errors).to be_empty, errors.map(&:to_h)
          end
        end
      end
    end

    it 'should raise on unrecognized link_id' do
      expect do
        definition.validate_form_values({
          **completed_values,
          some_fake_link_id: 'foo',
        }.stringify_keys)
      end.to raise_error(RuntimeError, /Unrecognized link ID: some_fake_link_id/)
    end
  end

  describe 'Validating custom data element definitions on publish' do
    let!(:definition) { create :hmis_form_definition, role: 'CUSTOM_ASSESSMENT' }
    let!(:cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment' }

    context 'with a valid mapping' do
      it 'should pass' do
        definition.definition = {
          'item': [
            {
              'type': 'STRING',
              'link_id': 'a_string',
              'text': 'A string',
              'mapping': { 'custom_field_key': cded.key },
            },
          ],
        }

        expect(definition.validate_json_form(is_publishing: true)).to be_empty
      end
    end

    it 'should fail when the CDED key does not exist' do
      definition.definition = {
        'item': [
          {
            'type': 'STRING',
            'link_id': 'a_string',
            'text': 'A string',
            'mapping': { 'custom_field_key': 'invalid_key' },
          },
        ],
      }

      expect do
        definition.validate_json_form(is_publishing: true)
      end.to raise_error('Item a_string has a custom_field_key mapping, but the CDED does not exist in the database. key = invalid_key, owner_type = Hmis::Hud::CustomAssessment')
    end

    it 'should fail when the CDED key exists but is associated with the wrong owner type for this form role' do
      definition.role = 'SERVICE'
      definition.definition = {
        'item': [
          {
            'type': 'STRING',
            'link_id': 'a_string',
            'text': 'A string',
            'mapping': { 'custom_field_key': cded.key },
          },
        ],
      }

      expect do
        definition.validate_json_form(is_publishing: true)
      end.to raise_error("Item a_string has a custom_field_key mapping, but the CDED does not exist in the database. key = #{cded.key}, owner_type = Hmis::Hud::HmisService")
    end

    it 'should fail if the CDED field type is incompatible with the item type' do
      definition.definition = {
        'item': [
          {
            'type': 'BOOLEAN',
            'link_id': 'a_bool',
            'text': 'A boolean',
            'mapping': { 'custom_field_key': cded.key },
          },
        ],
      }

      expect do
        definition.validate_json_form(is_publishing: true)
      end.to raise_error("Item a_bool has type BOOLEAN, but its custom field key #{cded.key} has an incompatible type string")
    end
  end
end
