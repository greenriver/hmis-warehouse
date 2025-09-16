# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate, class: 'Hmis::Ce::Match::Candidate' do
    transient do
      client { create :destination_client }
      priority_score { nil } # convenience helper, so caller can provide a single priority score value to the factory
    end
    association(:candidate_pool, factory: :hmis_ce_match_candidate_pool)
    client_proxy { build(:hmis_ce_client_proxy, client: client) }
    priority_scores { [1] }
    after(:build) do |candidate, evaluator|
      candidate.priority_scores = [evaluator.priority_score] if evaluator.priority_score
    end
  end
end
