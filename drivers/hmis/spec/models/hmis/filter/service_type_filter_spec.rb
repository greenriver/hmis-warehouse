###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

RSpec.describe Hmis::Filter::ServiceTypeFilter, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  # Limited to the categories built here, since the test database may hold seeded HUD service types
  let(:base_scope) { Hmis::Hud::CustomServiceType.where(custom_service_category_id: [financial_category.id, housing_category.id]) }

  let!(:financial_category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Financial Assistance') }
  let!(:housing_category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Housing') }

  let!(:rental_assistance) { create(:hmis_custom_service_type, data_source: data_source, custom_service_category: financial_category, name: 'Rental Assistance', supports_bulk_assignment: true) }
  let!(:security_deposit) { create(:hmis_custom_service_type, data_source: data_source, custom_service_category: financial_category, name: 'Security Deposit', supports_bulk_assignment: false) }
  let!(:housing_navigation) { create(:hmis_custom_service_type, data_source: data_source, custom_service_category: housing_category, name: 'Housing Navigation', supports_bulk_assignment: false) }

  def apply_filter(**filters)
    described_class.new(OpenStruct.new(**filters)).filter_scope(base_scope)
  end

  describe 'service category filter' do
    it 'filters to one category' do
      expect(apply_filter(service_category: [financial_category.id])).to contain_exactly(rental_assistance, security_deposit)
    end

    it 'returns the union of multiple categories' do
      expect(apply_filter(service_category: [financial_category.id, housing_category.id])).to contain_exactly(rental_assistance, security_deposit, housing_navigation)
    end

    it 'returns no rows for an unknown category' do
      expect(apply_filter(service_category: [-1])).to be_empty
    end

    it 'leaves the scope unchanged when unset' do
      expect(apply_filter(service_category: nil)).to contain_exactly(rental_assistance, security_deposit, housing_navigation)
      expect(apply_filter(service_category: [])).to contain_exactly(rental_assistance, security_deposit, housing_navigation)
    end
  end

  describe 'supports bulk assignment filter' do
    it 'filters to service types that support bulk assignment' do
      expect(apply_filter(supports_bulk_assignment: 'YES')).to contain_exactly(rental_assistance)
    end

    it 'filters to service types that do not support bulk assignment' do
      expect(apply_filter(supports_bulk_assignment: 'NO')).to contain_exactly(security_deposit, housing_navigation)
    end

    it 'leaves the scope unchanged when unset' do
      expect(apply_filter(supports_bulk_assignment: nil)).to contain_exactly(rental_assistance, security_deposit, housing_navigation)
    end
  end

  describe 'combined filters' do
    it 'requires both category and bulk assignment to match' do
      expect(apply_filter(service_category: [financial_category.id], supports_bulk_assignment: 'NO')).to contain_exactly(security_deposit)
    end
  end

  # Search term matching itself is covered by the CustomServiceType.matching_search_term spec
  describe 'search term filter' do
    it 'applies the search term scope' do
      expect(apply_filter(search_term: 'Rental')).to contain_exactly(rental_assistance)
    end
  end

  describe 'hud services' do
    let!(:hud_service_type) { create(:hmis_custom_service_type_for_hud_service, data_source: data_source, custom_service_category: housing_category) }

    it 'excludes hud services by default' do
      expect(apply_filter).not_to include(hud_service_type)
    end

    it 'includes hud services when requested' do
      expect(apply_filter(include_hud_services: true)).to include(hud_service_type)
    end

    it 'excludes hud services that are in a filtered category' do
      expect(apply_filter(service_category: [housing_category.id])).to contain_exactly(housing_navigation)
    end
  end
end
