# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_pool_unit_group_assignment, class: 'Hmis::Ce::Match::CandidatePoolUnitGroupAssignment' do
    association :unit_group, factory: :hmis_unit_group
    association :candidate_pool, factory: :hmis_ce_match_candidate_pool
    started_at { 2.weeks.ago }
    ended_at { nil }
  end
end
