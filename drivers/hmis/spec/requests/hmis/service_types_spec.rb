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

  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:financial_category) { create :hmis_custom_service_category, data_source: ds1, name: 'Financial Assistance' }
  let!(:housing_category) { create :hmis_custom_service_category, data_source: ds1, name: 'Housing' }
  let!(:rental_assistance) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: financial_category, name: 'Rental Assistance', supports_bulk_assignment: true }
  let!(:security_deposit) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: financial_category, name: 'Security Deposit' }
  let!(:housing_navigation) { create :hmis_custom_service_type, data_source: ds1, custom_service_category: housing_category, name: 'Housing Navigation' }

  before(:each) do
    hmis_login(user)
  end

  describe 'Service types query' do
    let(:query) do
      <<~GRAPHQL
        query GetServiceTypes($filters: ServiceTypeFilterOptions) {
          serviceTypes(filters: $filters) {
            nodesCount
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    def service_type_names(**filters)
      response, result = post_graphql(filters: filters) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'serviceTypes', 'nodes').pluck('name')
    end

    # The base setup seeds its own service types and categories, so filters that are not themselves
    # category-based are combined with a category filter to keep the expected rows deterministic.
    def service_type_names_in_own_categories(**filters)
      service_type_names(service_category: [financial_category.id, housing_category.id], **filters)
    end

    it 'filters by service category' do
      expect(service_type_names(service_category: [financial_category.id])).to contain_exactly('Rental Assistance', 'Security Deposit')
    end

    it 'filters by multiple service categories' do
      expect(service_type_names(service_category: [financial_category.id, housing_category.id])).to contain_exactly('Rental Assistance', 'Security Deposit', 'Housing Navigation')
    end

    it 'filters to service types that support bulk assignment' do
      expect(service_type_names_in_own_categories(supports_bulk_assignment: 'YES')).to contain_exactly('Rental Assistance')
    end

    it 'filters to service types that do not support bulk assignment' do
      expect(service_type_names_in_own_categories(supports_bulk_assignment: 'NO')).to contain_exactly('Security Deposit', 'Housing Navigation')
    end

    it 'filters by search term' do
      expect(service_type_names_in_own_categories(search_term: 'Rental')).to contain_exactly('Rental Assistance')
    end
  end

  describe 'Service type lookup' do
    let(:query) do
      <<~GRAPHQL
        query GetServiceTypeDetails($id: ID!) {
          serviceType(id: $id) {
            id
            name
          }
        }
      GRAPHQL
    end

    it 'resolves the service type' do
      response, result = post_graphql(id: rental_assistance.id) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'serviceType', 'name')).to eq('Rental Assistance')
    end

    it 'denies access without permission to configure data collection' do
      remove_permissions(access_control, :can_configure_data_collection)
      expect_access_denied(post_graphql(id: rental_assistance.id) { query })
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
