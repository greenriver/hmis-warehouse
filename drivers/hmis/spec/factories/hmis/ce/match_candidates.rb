# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate, class: 'Hmis::Ce::Match::Candidate' do
    transient do
      client { build :destination_client }
    end
    association(:candidate_pool, factory: :hmis_ce_match_candidate_pool)
    client_proxy { build(:hmis_ce_client_proxy, client: client) }
    priority_score { 1 }
  end
end
