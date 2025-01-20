FactoryBot.define do
  factory :hmis_ce_match_candidate, class: 'Hmis::Ce::Match::Candidate' do
    association(:candidate_pool, factory: :hmis_ce_match_candidate_pool)
    association(:client, factory: :hmis_hud_client)
    priority_score { 1 }
  end
end
