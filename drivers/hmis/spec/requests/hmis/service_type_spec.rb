#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

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

  before(:each) do
    hmis_login(user)
  end

  include_context 'hmis base setup'

  let(:create_service_type) do
    <<~GRAPHQL
      mutation CreateServiceType($input: ServiceTypeInput!) {
        createServiceType(input: $input) {
          serviceType {
            id
            name
            category
          }
        #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:update_service_type) do
    <<~GRAPHQL
      mutation UpdateServiceType($id: ID!, $input: ServiceTypeInput) {
        updateServiceType(id: $id, input: $input) {
          serviceType {
            id,
            name,
            category,
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
      response, result = post_graphql(input: mutation_input) { create_service_type }
      expect(response.status).to eq(200), result.inspect
      created_id = result.dig('data', 'createServiceType', 'serviceType', 'id')
      service_type = Hmis::Hud::CustomServiceType.find(created_id)
      expect(service_type.name).to eq('A new type with a new category')
      expect(service_type.custom_service_category.name).to eq('A brand new category')
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
      expect(service_type['category']).to eq('A new service category')
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
        expect_access_denied(post_graphql(name: 'foo', id: hud_type.id, supportsBulkAssignment: true) { update_service_type })
      end

      it 'should not allow deleting' do
        expect_access_denied(post_graphql(id: hud_type.id) { delete_service_type })
      end

      it 'should not allow creating a custom service type in the HUD category' do
        mutation_input = { serviceCategoryId: hud_category.id, name: 'This is not allowed' }
        expect_access_denied(post_graphql(input: mutation_input) { create_service_type })
      end

      it 'should not allow updating a custom service type into the HUD category' do
        input = { serviceCategoryId: hud_category.id }
        expect_access_denied(post_graphql(id: custom_type.id, input: input) { update_service_type })
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
