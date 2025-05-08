# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_client_search_query, class: 'GrdaWarehouse::ClientSearchQuery' do
    association :user
    params { { q: 'test search' } }
    fingerprint { GrdaWarehouse::ClientSearchQuery.generate_fingerprint(params) }
    created_at { Time.current }
  end
end
