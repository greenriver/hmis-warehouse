###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::DefinitionValidator, type: :model do
  def expect_validation_errors(definition:, role: nil, expected_errors: [])
    errors = Hmis::Form::DefinitionValidator.perform(definition, role)

    msgs = errors.map(&:full_message)

    expect(errors.count).to eq(expected_errors.count), msgs.join(', ')
    expect(msgs).to contain_exactly(*expected_errors.map { |regex| match(regex) })
    errors
  end

  let(:valid_display_item) do
    {
      "link_id": 'display_item',
      "type": 'DISPLAY',
      "text": 'text here',
    }.stringify_keys
  end

  context 'with invalid json structure' do
    let(:definition) do
      { "item": [{ **valid_display_item, "invalidkey": 'foo' }] }.deep_stringify_keys
    end

    it 'should error' do
      expect_validation_errors(definition: definition, expected_errors: [/invalidkey/])
    end
  end

  context 'with duplicated link ID' do
    let(:definition) do
      { "item": [valid_display_item, valid_display_item] }.deep_stringify_keys
    end
    it 'should error' do
      expect_validation_errors(definition: definition, expected_errors: [/Duplicate link ID/])
    end
  end

  context 'with invalid link ID' do
    let(:definition) do
      { "item": [{ **valid_display_item, "link_id": 'has-hyphens' }] }.deep_stringify_keys
    end

    it 'should error' do
      expect_validation_errors(definition: definition, expected_errors: [/does not match pattern/])
    end
  end

  context 'with invalid pick list reference' do
    let(:definition) do
      {
        "item": [
          {
            "link_id": 'choice',
            "type": 'CHOICE',
            "text": 'text here',
            "pick_list_reference": 'NotARealPickList',
          },
        ],
      }.deep_stringify_keys
    end
    it 'should error' do
      expect_validation_errors(definition: definition, expected_errors: [/Invalid pick list/])
    end
  end

  context 'reference validation' do
    let(:definition) do
      {
        "item": [
          {
            "link_id": 'bool',
            "type": 'BOOLEAN',
            "text": 'yes or no',
          },
          {
            "link_id": 'display_item',
            "type": 'DISPLAY',
            "text": 'text here',
            "hidden": false,
            "enable_behavior": 'ALL',
            "enable_when": [
              {
                "question": 'bool',
                "operator": 'EQUAL',
                "answer_boolean": true,
              },
            ],
          },
        ],
      }.deep_stringify_keys
    end

    it 'should succeed when valid' do
      expect_validation_errors(definition: definition, expected_errors: [])
    end

    it 'should produce errors when invalid' do
      definition['item'][1]['enable_when'][0]['question'] = 'invalidkey' # break the reference
      expect_validation_errors(definition: definition, expected_errors: [/invalidkey/])
    end
  end

  context 'HUD assessment missing required fields' do
    let(:definition) do
      {
        "item": [
          {
            "link_id": 'c3_youth_education_status',
            "type": 'BOOLEAN',
            "text": 'yes or no',
          },
        ],
      }.deep_stringify_keys
    end

    it 'should fail when INTAKE is missing required fields' do
      errors = expect_validation_errors(definition: definition, role: :INTAKE, expected_errors: [/Missing required link IDs/])
      expect(errors.first.full_message).not_to match(/c3_youth_education_status/) # should not include this one, since it was present
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

        expect(definition.validate_json_form).to be_empty
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
        definition.validate_json_form
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
        definition.validate_json_form
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
        definition.validate_json_form
      end.to raise_error("Item a_bool has type BOOLEAN, but its custom field key #{cded.key} has an incompatible type string")
    end
  end
end
