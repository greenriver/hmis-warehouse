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
      mutation UpdateServiceType($id: ID!, $name: String!, $supportsBulkAssignment: Boolean!) {
        updateServiceType(id: $id, name: $name, supportsBulkAssignment: $supportsBulkAssignment) {
          serviceType {
            id,
            name,
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

  let!(:c1) { create :hmis_custom_service_category, data_source: ds1, name: 'A category' }
  let!(:t1) { create :hmis_custom_service_type, custom_service_category: c1, data_source: ds1, name: 'An old type' }

  describe 'when the user has access' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'should successfully create a service type' do
      mutation_input = { serviceCategoryId: c1.id, name: 'A new type' }
      response, result = post_graphql(input: mutation_input) { create_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type_id = result.dig('data', 'createServiceType', 'serviceType', 'id')
      expect(service_type_id).not_to be_nil
      service_type = Hmis::Hud::CustomServiceType.find(service_type_id)
      expect(service_type.name).to eq('A new type')
    end

    it 'should successfully update a service type' do
      expect(t1.name).to eq('An old type')
      expect(t1.supports_bulk_assignment).to eq(false)
      response, result = post_graphql(name: 'A renamed type', id: t1.id, supportsBulkAssignment: true) { update_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type = result.dig('data', 'updateServiceType', 'serviceType')
      expect(service_type['name']).to eq('A renamed type')
      expect(service_type['supportsBulkAssignment']).to eq(true)
      t1.reload
      expect(t1.name).to eq('A renamed type')
      expect(t1.supports_bulk_assignment).to eq(true)
    end

    it 'should successfully delete a service type' do
      response, result = post_graphql(id: t1.id) { delete_service_type }
      expect(response.status).to eq(200), result.inspect
      service_type_id = result.dig('data', 'deleteServiceType', 'serviceType', 'id')
      expect(service_type_id).not_to be_nil
      t1.reload
      expect(t1.date_deleted).not_to be_nil
    end

    describe 'but the service type has services' do
      let!(:s1) { create :hmis_custom_service, custom_service_type: t1, data_source: ds1 }
      it 'should fail to delete' do
        response, result = post_graphql(id: t1.id) { delete_service_type }
        expect(response.status).to eq(200), result.inspect
        msg = result.dig('data', 'deleteServiceType', 'errors', 0, 'fullMessage')
        expect(msg).to eq('Cannot delete a service type that has services')
      end
    end

    describe 'when the service type is a HUD service type' do
      let!(:t1) { create :hmis_custom_service_type, custom_service_category: c1, data_source: ds1, name: 'PATH', hud_record_type: 141, hud_type_provided: 1 }

      it 'should not allow editing' do
        expect_gql_error(post_graphql(name: 'foo', id: t1.id, supportsBulkAssignment: true) { update_service_type })
      end

      it 'should not allow deleting' do
        expect_gql_error(post_graphql(id: t1.id) { delete_service_type })
      end
    end
  end

  describe 'when the user does not have access' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: [:can_configure_data_collection]) }

    it 'should throw an error when trying to create a service type' do
      mutation_input = { serviceCategoryId: c1.id, name: 'A new type' }
      expect_access_denied(post_graphql(input: mutation_input) { create_service_type })
    end
  end
end
