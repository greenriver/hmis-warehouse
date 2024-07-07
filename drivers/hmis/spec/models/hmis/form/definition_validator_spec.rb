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
end
