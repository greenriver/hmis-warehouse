# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_event, class: 'Hmis::Ce::Match::CandidateEvent' do
    association(:candidate_pool, factory: :hmis_ce_match_candidate_pool)
    association(:client_proxy, factory: :hmis_ce_client_proxy)
    snapshot { {} }
    event_name { 'add' } # add, update, remove
    created_at { Time.current }
  end
end
