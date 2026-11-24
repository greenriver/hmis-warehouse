###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:fd1) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: Hmis::Form::Definition::DRAFT, data_source: ds1 }
  let!(:fd2) { create :hmis_form_definition, role: :CUSTOM_ASSESSMENT, data_source: ds1 }
  let!(:fd3) { create :hmis_form_definition, role: :CLIENT, data_source: ds1 }

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
            role
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

  it 'should work when updating title' do
    input = { title: 'a new title!' }
    _response, result = post_graphql(id: fd1.id, input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
    expect(result.dig('data', 'updateFormDefinition', 'formDefinition', 'title')).to eq('a new title!')
  end

  it 'should error when the user does not have permission' do
    remove_permissions(access_control, :can_administrate_config)
    input = { title: 'anything' } # Can't update fd3 (CLIENT role) without can_administrate_config
    expect_access_denied post_graphql(id: fd3.id, input: input) { mutation }

    remove_permissions(access_control, :can_manage_forms)
    input = { title: 'a new title!' } # Can't update any forms (even CUSTOM_ASSESSMENT role) without can_manage_forms
    expect_access_denied post_graphql(id: fd1.id, input: input) { mutation }
  end

  describe 'external form object key' do
    let!(:external_form) { create :hmis_external_form_definition, status: Hmis::Form::Definition::DRAFT, external_form_object_key: nil, data_source: ds1 }

    def update_key(definition, key)
      post_graphql(id: definition.id, input: { external_form_object_key: key }) { mutation }
    end

    it 'sets a valid key' do
      response, result = update_key(external_form, 'pit/pit_2027')
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
      expect(external_form.reload.external_form_object_key).to eq('pit/pit_2027')
    end

    it 'accepts a key at the 100 character limit' do
      key = 'a' * 100
      response, result = update_key(external_form, key)
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
      expect(external_form.reload.external_form_object_key).to eq(key)
    end

    {
      'PIT-2027' => 'must contain only lowercase letters',
      '/pit' => 'must contain only lowercase letters',
      'pit/' => 'must contain only lowercase letters',
      'pit//2027' => 'must contain only lowercase letters',
      '../pit' => 'must contain only lowercase letters',
      'pit 2027' => 'must contain only lowercase letters',
      'a' * 101 => 'is too long (maximum is 100 characters)',
    }.each do |key, message|
      it "rejects invalid key #{key.truncate(20).inspect}" do
        response, result = update_key(external_form, key)
        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'updateFormDefinition', 'errors')
        expect(errors.map { |e| e['message'] }).to contain_exactly(start_with(message))
        expect(external_form.reload.external_form_object_key).to be_nil
      end
    end

    it 'rejects a key used by a different form' do
      other_form = create :hmis_external_form_definition, data_source: ds1
      response, result = update_key(external_form, other_form.external_form_object_key)
      expect(response.status).to eq(200), result.inspect
      errors = result.dig('data', 'updateFormDefinition', 'errors')
      expect(errors.map { |e| e['fullMessage'] }).to contain_exactly('External Form Key is already used by a different form. To reuse it, retire the other forms that use it.')
      expect(external_form.reload.external_form_object_key).to be_nil
    end

    context 'when the key is set and the form has never been published' do
      before { external_form.update!(external_form_object_key: 'pit-2027') }

      it 'allows changing it' do
        response, result = update_key(external_form, 'pit-2028')
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
        expect(external_form.reload.external_form_object_key).to eq('pit-2028')
      end

      it 'clears it when given a blank key' do
        response, result = update_key(external_form, '  ')
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
        expect(external_form.reload.external_form_object_key).to be_nil
      end
    end

    it 'strips whitespace from the key' do
      response, result = update_key(external_form, ' pit-2027 ')
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
      expect(external_form.reload.external_form_object_key).to eq('pit-2027')
    end

    context 'when the key is set and a previous version has been published' do
      before do
        create :hmis_external_form_definition, identifier: external_form.identifier, version: 0, status: Hmis::Form::Definition::RETIRED, external_form_object_key: 'pit-2027', data_source: ds1
        external_form.update!(version: 1, external_form_object_key: 'pit-2027')
      end

      it 'accepts the same key' do
        response, result = update_key(external_form, 'pit-2027')
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
      end

      it 'does not allow changing it' do
        expect_gql_error update_key(external_form, 'pit-2028'), message: 'not allowed to change external form object key after the form has been published'
        expect(external_form.reload.external_form_object_key).to eq('pit-2027')
      end

      it 'does not allow clearing it' do
        expect_gql_error update_key(external_form, nil), message: 'not allowed to change external form object key after the form has been published'
        expect(external_form.reload.external_form_object_key).to eq('pit-2027')
      end

      it 'keeps the key when the input does not include it' do
        response, result = post_graphql(id: external_form.id, input: { title: 'PIT 2027' }) { mutation }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
        expect(external_form.reload.external_form_object_key).to eq('pit-2027')
      end
    end

    it 'allows setting a key on a published form that has none' do
      create :hmis_external_form_definition, identifier: external_form.identifier, version: 0, status: Hmis::Form::Definition::PUBLISHED, external_form_object_key: nil, data_source: ds1
      external_form.update!(version: 1)
      response, result = update_key(external_form, 'pit-2027')
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'updateFormDefinition', 'errors')).to be_empty
      expect(external_form.reload.external_form_object_key).to eq('pit-2027')
    end
  end
end
