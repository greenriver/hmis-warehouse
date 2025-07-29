# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_pool, class: 'Hmis::Ce::Match::CandidatePool' do
    requirement_expression { 'TRUE' }
    sequence(:priority_expression, &:to_s)
  end
end
