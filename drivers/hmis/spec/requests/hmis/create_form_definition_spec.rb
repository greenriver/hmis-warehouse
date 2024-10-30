#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: :can_administrate_config) }

  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation CreateFormDefinition($input: FormDefinitionInput!) {
        createFormDefinition(input: $input) {
          formDefinition {
            id
            role
            title
            status
            identifier
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should successfully create a new form' do
    input = {
      definition: '',
      role: 'SERVICE',
      title: 'A new service',
      identifier: 'a_new_service',
    }
    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'createFormDefinition', 'errors')).to be_empty
    d = result.dig('data', 'createFormDefinition', 'formDefinition')
    expect(d['role']).to eq('SERVICE')
    expect(d['status']).to eq('draft')
  end

  it 'should fail if a non-admin user tries to create a non-editable form' do
    input = {
      definition: '',
      role: 'CLIENT',
      title: 'Client',
      identifier: 'a-new-client',
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'should fail if no role is provided' do
    input = {
      definition: '',
      title: 'Client',
      identifier: 'client',
    }
    result, response = post_graphql(input: input) { mutation }
    expect(result.status).to eq(200)
    expect(response.dig('data', 'createFormDefinition', 'errors', 0, 'fullMessage')).to eq('Role must exist')
  end

  it 'should fail to create a new form with an invalid identifier' do
    input = {
      definition: '',
      role: 'CUSTOM_ASSESSMENT',
      title: 'A new custom assessment',
      identifier: '123_invalid!', # Invalid identifier
    }
    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    expect(result.dig('data', 'createFormDefinition', 'errors')).not_to be_empty
    error_message = result.dig('data', 'createFormDefinition', 'errors', 0, 'message')
    expect(error_message).to match(/must contain only alphanumeric characters, underscores, and dashes/i)
  end
end
