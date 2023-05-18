###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetFormDefinition($enrollmentId: ID, $role: FormRole!) {
        getFormDefinition(enrollmentId: $enrollmentId, role: $role) {
          #{form_definition_fragment}
        }
      }
    GRAPHQL
  end

  Hmis::Form::Definition::FORM_ROLES.except(:CE, :POST_EXIT, :CUSTOM, :REFERRAL_REQUEST).keys.each do |role|
    it 'should find default definition by role' do
      response, result = post_graphql({ enrollment_id: e1.id.to_s, role: role }) { query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        form_definition = result.dig('data', 'getFormDefinition')
        expect(form_definition).to be_present
        expect(form_definition['role']).to eq(role.to_s)
      end
    end
  end

  describe 'Service definition lookup' do
    include_context 'hmis service setup'
    let(:service_query) do
      <<~GRAPHQL
        query GetServiceFormDefinition($customServiceTypeId: ID!, $enrollmentId: ID!) {
          getServiceFormDefinition(customServiceTypeId: $customServiceTypeId, enrollmentId: $enrollmentId) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end
    let(:service_form_definition) do
      Hmis::Form::Definition.where(role: :SERVICE).first
    end

    it 'should find no definitions if there are no service-specific instances' do
      response, result = post_graphql({ enrollment_id: e1.id.to_s, custom_service_type_id: cst1.id.to_s }) { service_query }
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        form_definition = result.dig('data', 'getServiceFormDefinition')
        expect(form_definition).to be_nil
      end
    end

    it 'should find definition by service type if there is an instance for it (by project type and service type)' do
      create(
        :hmis_form_instance,
        entity_type: 'ProjectType',
        entity_id: p1.project_type,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: cst1.id,
      )

      response, result = post_graphql({ enrollment_id: e1.id.to_s, custom_service_type_id: cst1.id.to_s }) { service_query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        form_definition = result.dig('data', 'getServiceFormDefinition')
        expect(form_definition).to be_present
        expect(form_definition['id']).to eq(service_form_definition.id.to_s)
      end
    end

    it 'should find definition by service type if there is an instance for it (by project and service category)' do
      create(
        :hmis_form_instance,
        entity: p1,
        definition_identifier: service_form_definition.identifier,
        custom_service_category_id: csc1.id,
      )

      response, result = post_graphql({ enrollment_id: e1.id.to_s, custom_service_type_id: cst1.id.to_s }) { service_query }

      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        form_definition = result.dig('data', 'getServiceFormDefinition')
        expect(form_definition).to be_present
        expect(form_definition['id']).to eq(service_form_definition.id.to_s)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
