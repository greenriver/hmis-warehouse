# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_pool, class: 'Hmis::Ce::Match::CandidatePool' do
    requirement_expression { 'TRUE' }
    # Use a sequence because candidate pools have a uniqueness constraint on requirement + priority
    sequence(:priority_expression) { |n| "{#{n}}" }
  end
end
