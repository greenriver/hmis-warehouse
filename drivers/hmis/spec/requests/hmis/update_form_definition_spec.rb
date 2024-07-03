#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:fd1) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: Hmis::Form::Definition::DRAFT }
  let!(:fd2) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateFormDefinition($id: ID!, $input: FormDefinitionInput!) {
        updateFormDefinition(id: $id, input: $input) {
          formDefinition {
            id
            title
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should work when the definition needs to be converted' do
    input = {
      definition: '{ "__typename": "FormDefinitionJson", "item": [ { "__typename": "FormItem", "item": [ { "__typename": "FormItem", "linkId": "link_1", "type": "DATE", "text": "Assessment Date", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "assessmentDate": true, "disabledDisplay": "HIDDEN" }, { "__typename": "FormItem", "linkId": "emergency_contact_name", "type": "STRING", "text": "Emergency Contact Name 1", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "mapping": { "__typename": "FieldMapping", "customFieldKey": "emergency_contact_name" }, "disabledDisplay": "HIDDEN" } ], "linkId": "event_group", "type": "GROUP", "text": "SPDAT", "hidden": false, "mapping": null, "prefill": false, "disabledDisplay": "HIDDEN" } ] }',
    }
    response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
  end

  it 'should work when converting nested attributes like autofill_when' do
    input = {
      definition: '{ "__typename": "FormDefinitionJson", "item": [ { "__typename": "FormItem", "linkId": "yes_or_no", "type": "CHOICE", "component": "CHECKBOX", "text": "Yes or no?", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "pickListReference": "NoYesMissing", "disabledDisplay": "HIDDEN" }, { "__typename": "FormItem", "linkId": "maybe", "type": "CHOICE", "component": "CHECKBOX", "text": "Maybe", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "pickListReference": "NoYesMissing", "disabledDisplay": "HIDDEN", "autofillValues": [ { "__typename": "AutofillValue", "valueCode": "YES", "autofillBehavior": "ALL", "autofillWhen": [ { "__typename": "EnableWhen", "question": "yes_or_no", "operator": "EQUAL", "answerCode": "YES" } ] } ] } ] }',
    }
    response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
  end

  it 'should work when form attributes include a list of strings' do
    input = {
      definition: '{ "__typename": "FormDefinitionJson", "item": [ { "__typename": "FormItem", "linkId": "question_1", "type": "CHOICE", "text": "Length of stay in prior living situation", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "pickListReference": "ResidencePriorLengthOfStay", "disabledDisplay": "HIDDEN" }, { "__typename": "FormItem", "linkId": "question_2", "type": "DISPLAY", "text": "Client stayed 90+ days in an institutional setting. This is considered a \\"break\\" according to the HUD definition of chronic homelessness. Stopping data collection for 3.917 Prior Living Situation.", "hidden": false, "disabledDisplay": "HIDDEN", "enableBehavior": "ALL", "enableWhen": [ { "__typename": "EnableWhen", "question": "question_1", "operator": "IN", "answerCodes": [ "NUM_90_DAYS_OR_MORE_BUT_LESS_THAN_ONE_YEAR", "ONE_YEAR_OR_LONGER" ] } ] }, { "linkId": "q253ac3e0_1fe7_44fc_8abb_4bdf4b617d22", "text": "CURRENCY", "type": "CURRENCY", "required": false, "warnIfEmpty": false, "hidden": false, "readOnly": false, "repeats": false, "disabledDisplay": "HIDDEN" } ] }',
    }
    response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
  end

  it 'should work when the definition does not need to be converted' do
    input = {
      definition: '{ "item": [ { "item": [ { "text": "Assessment Date", "type": "DATE", "hidden": false, "link_id": "link_1", "repeats": false, "required": false, "read_only": false, "warn_if_empty": false, "assessment_date": true, "disabled_display": "HIDDEN" }, { "text": "Emergency Contact Name", "type": "STRING", "hidden": false, "link_id": "emergency_contact_name", "mapping": { "custom_field_key": "emergency_contact_name" }, "repeats": false, "required": false, "read_only": false, "warn_if_empty": false, "disabled_display": "HIDDEN" } ], "text": "SPDAT", "type": "GROUP", "hidden": false, "link_id": "event_group", "prefill": false, "disabled_display": "HIDDEN" } ] }',
    }
    response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
  end

  it 'should raise an error if the form definition is not a draft' do
    input = {
      title: 'a new name for this form',
    }
    response, result = post_graphql(id: fd2.id, input: input) { mutation }
    expect(response.status).to eq(500), result.inspect
    expect(result.dig('errors', 0, 'message')).to eq('only allowed to modify draft forms')
  end

  it 'should work when no definition is provided' do
    input = { title: 'a new title!' }
    _response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
    expect(result.dig('data', 'updateFormDefinition', 'formDefinition', 'title')).to eq('a new title!')
  end
end
