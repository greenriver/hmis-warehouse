#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

# TODO(#5737) - deprecated, to remove
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

  let(:create_service_category) do
    <<~GRAPHQL
      mutation CreateServiceCategory($name: String!) {
        createServiceCategory(name: $name) {
          serviceCategory {
            id
            name
            hud
            serviceTypes {
              nodesCount
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:rename_service_category) do
    <<~GRAPHQL
      mutation RenameServiceCategory($id: ID!, $name: String!) {
        renameServiceCategory(id: $id, name: $name) {
          serviceCategory {
            id
            name
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let(:delete_service_category) do
    <<~GRAPHQL
      mutation DeleteServiceCategory($id: ID!) {
        deleteServiceCategory(id: $id) {
          serviceCategory {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:c1) { create :hmis_custom_service_category, data_source: ds1, name: 'An old category' }
  describe 'when the user has access' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'should successfully create a service category' do
      response, result = post_graphql(name: 'A new category') { create_service_category }
      expect(response.status).to eq(200), result.inspect
      service_category_id = result.dig('data', 'createServiceCategory', 'serviceCategory', 'id')
      expect(service_category_id).not_to be_nil
      service_category = Hmis::Hud::CustomServiceCategory.find(service_category_id)
      expect(service_category.name).to eq('A new category')
    end

    it 'should successfully rename a service category' do
      expect(c1.name).to eq('An old category')
      response, result = post_graphql(name: 'A renamed category', id: c1.id) { rename_service_category }
      expect(response.status).to eq(200), result.inspect
      service_category_name = result.dig('data', 'renameServiceCategory', 'serviceCategory', 'name')
      expect(service_category_name).to eq('A renamed category')
      c1.reload
      expect(c1.name).to eq('A renamed category')
    end

    it 'should successfully delete a service category' do
      response, result = post_graphql(id: c1.id) { delete_service_category }
      expect(response.status).to eq(200), result.inspect
      service_category_id = result.dig('data', 'deleteServiceCategory', 'serviceCategory', 'id')
      expect(service_category_id).not_to be_nil
      c1.reload
      expect(c1.date_deleted).not_to be_nil
    end

    describe 'but the service category has a service type' do
      let!(:t1) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: c1 }
      it 'should fail to delete' do
        response, result = post_graphql(id: c1.id) { delete_service_category }
        expect(response.status).to eq(500), result.inspect
        msg = result.dig('errors').first.dig('message')
        expect(msg).to eq('Cannot delete a service category that has service types')
      end
    end
  end

  describe 'when the user does not have access' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: [:can_configure_data_collection]) }

    it 'should throw an error when trying to create a service category' do
      expect_access_denied(post_graphql(name: 'A new category') { create_service_category })
    end
  end
end
