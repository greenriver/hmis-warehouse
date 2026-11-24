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

  let(:identifier) { 'a_new_service' }
  # Cruft: there's an existing form with this identifier in a different DS, which should be ignored
  let!(:cruft_form) { create(:hmis_form_definition, identifier: identifier) }

  it 'should successfully create a new form' do
    input = {
      definition: '',
      role: 'SERVICE',
      title: 'A new service',
      identifier: identifier,
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

  it 'should fail to create a new form with a non-unique identifier' do
    create(:hmis_form_definition, identifier: identifier, data_source: ds1)
    input = {
      definition: '',
      role: 'SERVICE',
      title: 'A new service',
      identifier: identifier,
    }
    response, result = post_graphql(input: input) { mutation }
    expect(response.status).to eq(200), result.inspect
    errors = result.dig('data', 'createFormDefinition', 'errors')
    expect(errors).not_to be_empty
    expect(errors.first['fullMessage']).to eq('Identifier is not unique. Please choose another identifier.')
  end

  it 'does not let a non-admin user set an external form object key on another form role' do
    input = { definition: '', role: 'SERVICE', title: 'A new service', identifier: identifier, external_form_object_key: 'pit-2027' }
    expect do
      response, result = post_graphql(input: input) { mutation }
      expect(response.status).to eq(200), result.inspect
      errors = result.dig('data', 'createFormDefinition', 'errors')
      expect(errors.map { |e| e['message'] }).to contain_exactly('can only be set on External Forms')
    end.not_to change(Hmis::Form::Definition, :count)
  end

  describe 'external form object key' do
    let(:input) { { role: 'EXTERNAL_FORM', title: 'PIT 2027', identifier: 'pit_2027', definition: '' } }

    it 'creates the form without a key when the key is blank' do
      add_permissions(access_control, :can_administrate_config)
      response, result = post_graphql(input: input.merge(external_form_object_key: '')) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createFormDefinition', 'errors')).to be_empty
      expect(Hmis::Form::Definition.find_by!(identifier: 'pit_2027', data_source: ds1).external_form_object_key).to be_nil
    end
    before { add_permissions(access_control, :can_administrate_config) } # required to create External Forms

    it 'sets the key on a new external form' do
      response, result = post_graphql(input: input.merge(external_form_object_key: 'pit/pit-2027')) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createFormDefinition', 'errors')).to be_empty
      expect(Hmis::Form::Definition.find_by!(identifier: 'pit_2027', data_source: ds1).external_form_object_key).to eq('pit/pit-2027')
    end

    it 'rejects an invalid key' do
      expect do
        response, result = post_graphql(input: input.merge(external_form_object_key: 'PIT 2027')) { mutation }
        expect(response.status).to eq(200), result.inspect
        errors = result.dig('data', 'createFormDefinition', 'errors')
        expect(errors.map { |e| e['message'] }).to contain_exactly(start_with('must contain only lowercase letters'))
      end.not_to change(Hmis::Form::Definition, :count)
    end
  end
end
