# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate, class: 'Hmis::Ce::Match::Candidate' do
    association(:candidate_pool, factory: :hmis_ce_match_candidate_pool)
    association(:client_proxy, factory: :hmis_ce_client_proxy)
    priority_score { 1 }
  end
end
