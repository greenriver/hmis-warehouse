# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_pool, class: 'Hmis::Ce::Match::CandidatePool' do
    requirement_expression { 'TRUE' }
    priority_expression { '0' }
    configuration_updated_at { Date.new(2024, 1, 1) }
  end
end
