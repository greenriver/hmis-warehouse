###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Create Form Rule Mutation', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_configure_data_collection, :can_view_project]) }

  let!(:form_definition) { create(:hmis_form_definition, identifier: 'test-custom-assessment', role: :CUSTOM_ASSESSMENT, status: :published) }

  before(:each) do
    hmis_login(user)
  end

  subject(:mutation) do
    <<~GRAPHQL
      mutation CreateFormRule($input: CreateFormRuleInput!) {
        createFormRule(input: $input) {
          formRule {
            id
            definitionId
            definitionRole
            projectId
            active
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  context 'when creating a project-level rule' do
    let(:input) do
      {
        input: {
          definitionId: form_definition.id,
          input: {
            projectId: p1.id,
          },
        },
      }
    end

    it 'creates the form rule' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        form_rule = result.dig('data', 'createFormRule', 'formRule')
        expect(form_rule).to be_present
        expect(form_rule['definitionId']).to eq(form_definition.id.to_s)
        expect(form_rule['projectId']).to eq(p1.id.to_s)
        expect(form_rule['active']).to eq(true)
      end.to change(Hmis::Form::Instance, :count).by(1)
    end
  end

  context 'when creating an organization-level rule' do
    let(:input) do
      {
        input: {
          definitionId: form_definition.id,
          input: {
            organizationId: o1.id,
          },
        },
      }
    end

    it 'creates the form rule' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        form_rule = result.dig('data', 'createFormRule', 'formRule')
        expect(form_rule).to be_present
        expect(form_rule['definitionId']).to eq(form_definition.id.to_s)
        expect(form_rule['projectId']).to be_nil
      end.to change(Hmis::Form::Instance, :count).by(1)
    end
  end

  context 'when creating a SERVICE role rule' do
    let!(:service_definition) { create(:hmis_form_definition, identifier: 'test-service', role: :SERVICE, status: :published) }
    let!(:service_category) { create(:hmis_custom_service_category, name: 'Test Category') }

    let(:input) do
      {
        input: {
          definitionId: service_definition.id,
          input: {
            projectId: p1.id,
            serviceCategoryId: service_category.id,
          },
        },
      }
    end

    it 'creates the form rule' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        form_rule = result.dig('data', 'createFormRule', 'formRule')
        expect(form_rule).to be_present
        expect(form_rule['definitionRole']).to eq('SERVICE')
      end.to change(Hmis::Form::Instance, :count).by(1)
    end

    context 'when no service category or type is provided' do
      let(:input) do
        {
          input: {
            definitionId: service_definition.id,
            input: {
              projectId: p1.id,
            },
          },
        }
      end

      it 'raises a validation error' do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        errors = result.dig('data', 'createFormRule', 'errors')
        expect(errors).to be_present
        expect(errors.first['fullMessage']).to include('service category or service type')
      end
    end
  end

  context 'without permissions' do
    let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: [:can_configure_data_collection]) }
    let(:input) do
      {
        input: {
          definitionId: form_definition.id,
          input: {
            projectId: p1.id,
          },
        },
      }
    end

    it 'raises access denied error' do
      expect_access_denied post_graphql(input) { mutation }
    end
  end
end
