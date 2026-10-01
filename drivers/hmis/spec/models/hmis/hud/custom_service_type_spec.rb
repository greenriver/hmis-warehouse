###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomServiceType, type: :model do
  describe '.matching_search_term' do
    let(:data_source) { create(:hmis_data_source) }
    let!(:financial_category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Financial Assistance') }
    let!(:rental_assistance) { create(:hmis_custom_service_type, data_source: data_source, custom_service_category: financial_category, name: 'Rental Assistance') }
    let!(:security_deposit) { create(:hmis_custom_service_type, data_source: data_source, custom_service_category: financial_category, name: 'Security Deposit') }

    def search(search_term)
      Hmis::Hud::CustomServiceType.where(custom_service_category_id: financial_category.id).matching_search_term(search_term)
    end

    it 'matches on name' do
      expect(search('Rental')).to contain_exactly(rental_assistance)
    end

    it 'matches case-insensitively' do
      expect(search('rental')).to contain_exactly(rental_assistance)
    end

    it 'matches across words in order' do
      expect(search('Security Dep')).to contain_exactly(security_deposit)
    end

    it 'ignores surrounding whitespace' do
      expect(search('  Rental  ')).to contain_exactly(rental_assistance)
    end

    it 'does not match on category name, which has its own filter' do
      expect(search('Financial')).to be_empty
    end

    it 'returns no rows for a term that matches nothing' do
      expect(search('Transportation')).to be_empty
    end

    it 'returns no rows when the term is blank' do
      expect(search('')).to be_empty
      expect(search(nil)).to be_empty
    end
  end
end
