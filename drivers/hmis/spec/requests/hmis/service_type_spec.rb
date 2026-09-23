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

  # Must come after 'hmis base setup', since logging in resolves the data source that it creates
  before(:each) do
    hmis_login(user)
  end

  let(:create_service_type) do
    <<~GRAPHQL
      mutation CreateServiceType($input: ServiceTypeInput!) {
        createServiceType(input: $input) {
          serviceType {
            id
            name
            serviceCategory {
              id
              name
              __typename
            }
          }
        #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:update_service_type) do
    <<~GRAPHQL
      mutation UpdateServiceType($id: ID!, $input: ServiceTypeInput!) {
        updateServiceType(id: $id, input: $input) {
          serviceType {
            id,
            name,
            serviceCategory {
              id
              name
              __typename
            }
            supportsBulkAssignment
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:delete_service_type) do
    <<~GRAPHQL
      mutation DeleteServiceType($id: ID!) {
        deleteServiceType(id: $id) {
          serviceType {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:custom_category) { create :hmis_custom_service_category, data_source: ds1, name: 'A category' }
  let!(:custom_type) { create :hmis_custom_service_type, custom_service_category: custom_category, data_source: ds1, name: 'An old type' }

  describe 'when the user has access' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'should successfully create a service type' do
      mutation_input = { serviceCategoryId: custom_category.id, name: 'A new type' }
      response, result = post_graphql(input: mutation_input) { create_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type_id = result.dig('data', 'createServiceType', 'serviceType', 'id')
      expect(service_type_id).not_to be_nil
      service_type = Hmis::Hud::CustomServiceType.find(service_type_id)
      expect(service_type.name).to eq('A new type')
    end

    it 'should successfully create a service type with a new category' do
      mutation_input = { serviceCategoryName: 'A brand new category', name: 'A new type with a new category' }
      expect do
        response, result = post_graphql(input: mutation_input) { create_service_type }
        expect(response.status).to eq(200), result.inspect
        created_id = result.dig('data', 'createServiceType', 'serviceType', 'id')
        service_type = Hmis::Hud::CustomServiceType.find(created_id)
        expect(service_type.name).to eq('A new type with a new category')
        expect(service_type.custom_service_category.name).to eq('A brand new category')
      end.to change(Hmis::Hud::CustomServiceType, :count).by(1).
        and change(Hmis::Hud::CustomServiceCategory, :count).by(1)
    end

    it 'should successfully create a service type onto the same category when duplicate name is provided' do
      mutation_input = { serviceCategoryName: 'A category', name: 'A new type with a new category' }
      expect do
        response, result = post_graphql(input: mutation_input) { create_service_type }
        expect(response.status).to eq(200), result.inspect
        created_id = result.dig('data', 'createServiceType', 'serviceType', 'id')
        service_type = Hmis::Hud::CustomServiceType.find(created_id)
        expect(service_type.name).to eq('A new type with a new category')
        expect(service_type.custom_service_category).to eq(custom_category)
      end.to change(Hmis::Hud::CustomServiceType, :count).by(1).
        and not_change(Hmis::Hud::CustomServiceCategory, :count)
    end

    it 'should return a validation error when neither service category ID nor name is provided' do
      mutation_input = { name: 'This is not allowed' }
      response, result = post_graphql(input: mutation_input) { create_service_type }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'createServiceType', 'errors', 0, 'fullMessage')).to eq('Service category must exist')
    end

    it 'should successfully update a service type' do
      expect(custom_type.name).to eq('An old type')
      expect(custom_type.supports_bulk_assignment).to eq(false)
      mutation_input = {
        name: 'A renamed type',
        supportsBulkAssignment: true,
        serviceCategoryName: 'A new service category',
      }
      response, result = post_graphql(id: custom_type.id, input: mutation_input) { update_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type = result.dig('data', 'updateServiceType', 'serviceType')
      expect(service_type['name']).to eq('A renamed type')
      expect(service_type['supportsBulkAssignment']).to eq(true)
      expect(service_type['serviceCategory']['name']).to eq('A new service category')
      custom_type.reload
      expect(custom_type.name).to eq('A renamed type')
      expect(custom_type.supports_bulk_assignment).to eq(true)
      expect(custom_type.custom_service_category).not_to eq(custom_category)
      expect(custom_type.custom_service_category.name).to eq('A new service category')
    end

    it 'should successfully delete a service type' do
      response, result = post_graphql(id: custom_type.id) { delete_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type_id = result.dig('data', 'deleteServiceType', 'serviceType', 'id')
      expect(service_type_id).not_to be_nil
      custom_type.reload
      expect(custom_type.date_deleted).not_to be_nil
    end

    describe 'when the service type has services' do
      let!(:service) { create :hmis_custom_service, custom_service_type: custom_type, data_source: ds1 }

      it 'should fail to delete' do
        response, result = post_graphql(id: custom_type.id) { delete_service_type }
        expect(response.status).to eq(200), result.inspect
        msg = result.dig('data', 'deleteServiceType', 'errors', 0, 'fullMessage')
        expect(msg).to eq('Cannot delete a service type that has services')
      end
    end

    describe 'when there is a HUD service type' do
      let!(:hud_category) { create :hmis_custom_service_category, data_source: ds1, name: 'A HUD category' }
      let!(:hud_type) { create :hmis_custom_service_type, custom_service_category: hud_category, data_source: ds1, name: 'A HUD type', hud_record_type: 141, hud_type_provided: 1 }

      it 'should not allow editing' do
        mutation_input = { name: 'foo', supportsBulkAssignment: true }
        expect_gql_error(post_graphql(id: hud_type.id, input: mutation_input) { update_service_type })
      end

      it 'should not allow deleting' do
        expect_gql_error(post_graphql(id: hud_type.id) { delete_service_type })
      end
    end
  end

  describe 'formDefinitions' do
    let(:query) do
      <<~GRAPHQL
        query GetServiceType($id: ID!) {
          serviceType(id: $id) {
            id
            formDefinitions {
              id
              identifier
            }
          }
        }
      GRAPHQL
    end

    let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_configure_data_collection]) }

    let!(:type_form) { create :hmis_form_definition, identifier: 'type-service-form', role: :SERVICE, status: :published, data_source: ds1 }
    let!(:category_form) { create :hmis_form_definition, identifier: 'category-service-form', role: :SERVICE, status: :published, data_source: ds1 }

    def identifiers
      response, result = post_graphql(id: custom_type.id) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'serviceType', 'formDefinitions').map { |d| d['identifier'] }
    end

    context 'when the rules are active' do
      let!(:type_rule) { create :hmis_form_instance, definition: type_form, entity: nil, custom_service_type: custom_type, active: true, data_source: ds1 }
      let!(:category_rule) { create :hmis_form_instance, definition: category_form, entity: nil, custom_service_category: custom_category, active: true, data_source: ds1 }

      it 'includes forms enabled by service type and by service category' do
        expect(identifiers).to contain_exactly('type-service-form', 'category-service-form')
      end
    end

    context 'when the rules are inactive' do
      let!(:type_rule) { create :hmis_form_instance, definition: type_form, entity: nil, custom_service_type: custom_type, active: false, data_source: ds1 }
      let!(:category_rule) { create :hmis_form_instance, definition: category_form, entity: nil, custom_service_category: custom_category, active: false, data_source: ds1 }

      it 'excludes forms whose rules were deactivated' do
        expect(identifiers).to be_empty
      end
    end
  end

  describe 'when the user does not have access' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: [:can_configure_data_collection]) }

    it 'should throw an error when trying to create a service type' do
      mutation_input = { serviceCategoryId: custom_category.id, name: 'A new type' }
      expect_access_denied(post_graphql(input: mutation_input) { create_service_type })
    end
  end
end
