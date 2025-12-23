###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Delete Form Rule Mutation', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_configure_data_collection]) }

  let!(:form_definition) { create(:hmis_form_definition, identifier: 'test-custom-assessment', role: :CUSTOM_ASSESSMENT, status: :published) }
  let!(:form_instance) { create(:hmis_form_instance, definition: form_definition, entity: p1, active: true, system: false) }

  before(:each) do
    hmis_login(user)
  end

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteFormRule($id: ID!) {
        deleteFormRule(id: $id) {
          formRule {
            id
            definitionId
            active
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:input) do
    {
      id: form_instance.id,
    }
  end

  it 'marks the form rule as inactive' do
    expect do
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200), result.inspect

      form_rule = result.dig('data', 'deleteFormRule', 'formRule')
      expect(form_rule).to be_present
      expect(form_rule['id']).to eq(form_instance.id.to_s)
      expect(form_rule['active']).to eq(false)
    end.to change { form_instance.reload.active }.from(true).to(false)
  end

  context 'when deleting a system rule' do
    let!(:form_instance) { create(:hmis_form_instance, definition: form_definition, entity: p1, active: true, system: true) }

    it 'raises an error' do
      expect_gql_error post_graphql(input) { mutation }, message: 'cannot delete system rule'
    end
  end

  context 'when deleting a non-existent rule' do
    let(:input) do
      {
        id: '999999',
      }
    end

    it 'raises an error' do
      expect_gql_error post_graphql(input) { mutation }, message: 'not found'
    end
  end

  context 'without permissions' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: [:can_configure_data_collection]) }

    it 'raises access denied error' do
      expect_access_denied post_graphql(input) { mutation }
    end
  end
end
