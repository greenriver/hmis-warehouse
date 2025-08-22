# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::ClientProxy, type: :model do
  describe 'Scopes' do
    let!(:candidate_pool_1) { create(:hmis_ce_match_candidate_pool) }
    let!(:candidate_pool_2) { create(:hmis_ce_match_candidate_pool) }

    let!(:client_proxy_1) { create(:hmis_ce_client_proxy) }
    let!(:client_proxy_2) { create(:hmis_ce_client_proxy) }

    let!(:event_1) { create(:hmis_event, client_proxy: client_proxy_1, candidate_pool: candidate_pool_1, created_at: 1.day.ago) }
    let!(:event_2) { create(:hmis_event, client_proxy: client_proxy_1, candidate_pool: candidate_pool_1, created_at: 2.days.ago) }
    let!(:event_3) { create(:hmis_event, client_proxy: client_proxy_2, candidate_pool: candidate_pool_2, created_at: 1.day.ago) }

    describe '.join_latest_event_per_candidate_pool' do
      it 'returns client proxies with the latest event per candidate pool' do
        result = described_class.join_latest_event_per_candidate_pool

        expect(result).to include(client_proxy_1, client_proxy_2)
        expect(result).not_to include(event_2) # Ensure only the latest event is included
      end
    end

    describe '.filter_by_attribute' do
      let!(:client_proxy_with_attribute) { create(:hmis_ce_client_proxy, some_attribute: 'value') }
      let!(:client_proxy_without_attribute) { create(:hmis_ce_client_proxy, some_attribute: 'other_value') }

      it 'filters client proxies by the given attribute' do
        result = described_class.filter_by_attribute(:some_attribute, 'value')

        expect(result).to include(client_proxy_with_attribute)
        expect(result).not_to include(client_proxy_without_attribute)
      end
    end
  end
end
