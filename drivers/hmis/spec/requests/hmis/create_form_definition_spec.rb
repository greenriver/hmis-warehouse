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
      identifier: 'client',
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'should fail if no role is provided' do
    # todo @Martha - this fails, but will fix after merging release-124
    input = {
      definition: '',
      title: 'Client',
      identifier: 'client',
    }
    expect_gql_error post_graphql(input: input) { mutation }, message: /Definition invalid/
  end
end
