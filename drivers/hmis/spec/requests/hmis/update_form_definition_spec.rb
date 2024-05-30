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

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateFormDefinition($id: ID!, $input: FormDefinitionInput!) {
        updateFormDefinition(id: $id, input: $input) {
          formDefinition {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should work when the definition needs to be converted' do
    input = {
      definition: '{"__typename":"FormDefinitionJson","item":[{"__typename":"FormItem","item":[{"__typename":"FormItem","item":null,"linkId":"link_1","type":"DATE","component":null,"prefix":null,"text":"Assessment Date","briefText":null,"readonlyText":null,"helperText":null,"required":false,"warnIfEmpty":false,"hidden":false,"readOnly":false,"repeats":false,"mapping":null,"pickListReference":null,"size":null,"assessmentDate":true,"prefill":false,"bounds":null,"pickListOptions":null,"initial":null,"dataCollectedAbout":null,"disabledDisplay":"HIDDEN","enableBehavior":"ANY","enableWhen":null,"autofillValues":null},{"__typename":"FormItem","item":null,"linkId":"emergency_contact_name","type":"STRING","component":null,"prefix":null,"text":"Emergency Contact Name 1","briefText":null,"readonlyText":null,"helperText":null,"required":false,"warnIfEmpty":false,"hidden":false,"readOnly":false,"repeats":false,"mapping":{"__typename":"FieldMapping","recordType":null,"fieldName":null,"customFieldKey":"emergency_contact_name"},"pickListReference":null,"size":null,"assessmentDate":null,"prefill":false,"bounds":null,"pickListOptions":null,"initial":null,"dataCollectedAbout":null,"disabledDisplay":"HIDDEN","enableBehavior":"ANY","enableWhen":null,"autofillValues":null}],"linkId":"event_group","type":"GROUP","component":null,"prefix":null,"text":"SPDAT","briefText":null,"readonlyText":null,"helperText":null,"required":false,"warnIfEmpty":false,"hidden":false,"readOnly":false,"repeats":false,"mapping":null,"pickListReference":null,"size":null,"assessmentDate":null,"prefill":false,"bounds":null,"pickListOptions":null,"initial":null,"dataCollectedAbout":null,"disabledDisplay":"HIDDEN","enableBehavior":"ANY","enableWhen":null,"autofillValues":null}]}',
    }
    response, result = post_graphql(id: 30, input: input) { mutation }
    expect(response.status).to eq 200
    errors = result.dig('data', 'updateFormDefinition', 'errors')
    expect(errors).to be_empty
  end

  it 'should work when converting nested attributes like autofill_when' do
    input = {
      definition: '{"__typename":"FormDefinitionJson","item":[{"__typename":"FormItem","item":null,"linkId":"yes_or_no","type":"CHOICE","component":"CHECKBOX","prefix":null,"text":"Yes or no?","briefText":null,"readonlyText":null,"helperText":null,"required":false,"warnIfEmpty":false,"hidden":false,"readOnly":false,"repeats":false,"mapping":null,"pickListReference":"NoYesMissing","size":null,"assessmentDate":null,"prefill":false,"bounds":null,"pickListOptions":null,"initial":null,"dataCollectedAbout":null,"disabledDisplay":"HIDDEN","enableBehavior":"ANY","enableWhen":null,"autofillValues":null},{"__typename":"FormItem","item":null,"linkId":"maybe","type":"CHOICE","component":"CHECKBOX","prefix":null,"text":"Maybe","briefText":null,"readonlyText":null,"helperText":null,"required":false,"warnIfEmpty":false,"hidden":false,"readOnly":false,"repeats":false,"mapping":null,"pickListReference":"NoYesMissing","size":null,"assessmentDate":null,"prefill":false,"bounds":null,"pickListOptions":null,"initial":null,"dataCollectedAbout":null,"disabledDisplay":"HIDDEN","enableBehavior":"ANY","enableWhen":null,"autofillValues":[{"__typename":"AutofillValue","valueCode":"YES","valueQuestion":null,"valueBoolean":null,"valueNumber":null,"sumQuestions":null,"formula":null,"autofillBehavior":"ALL","autofillReadonly":null,"autofillWhen":[{"__typename":"EnableWhen","question":"yes_or_no","localConstant":null,"operator":"EQUAL","answerCode":"YES","answerCodes":null,"answerNumber":null,"answerBoolean":null,"answerGroupCode":null,"compareQuestion":null}]}]}]}',
    }
    response, result = post_graphql(id: 30, input: input) { mutation }
    expect(response.status).to eq 200
    errors = result.dig('data', 'updateFormDefinition', 'errors')
    expect(errors).to be_empty
  end

  it 'should work when the definition does not need to be converted' do
    input = {
      definition: '{"item":[{"item":[{"text":"Assessment Date","type":"DATE","hidden":false,"link_id":"link_1","prefill":false,"repeats":false,"required":false,"read_only":false,"warn_if_empty":false,"assessment_date":true,"enable_behavior":"ANY","disabled_display":"HIDDEN"},{"text":"Emergency Contact Name","type":"STRING","hidden":false,"link_id":"emergency_contact_name","mapping":{"custom_field_key":"emergency_contact_name"},"prefill":false,"repeats":false,"required":false,"read_only":false,"warn_if_empty":false,"enable_behavior":"ANY","disabled_display":"HIDDEN"}],"text":"SPDAT","type":"GROUP","hidden":false,"link_id":"event_group","prefill":false,"repeats":false,"required":false,"read_only":false,"warn_if_empty":false,"enable_behavior":"ANY","disabled_display":"HIDDEN"}]}',
    }
    response, result = post_graphql(id: 30, input: input) { mutation }
    expect(response.status).to eq 200
    errors = result.dig('data', 'updateFormDefinition', 'errors')
    expect(errors).to be_empty
  end
end
