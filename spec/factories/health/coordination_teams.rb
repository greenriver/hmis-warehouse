# frozen_string_literal: true

FactoryBot.define do
  factory :coordination_team, class: 'Health::CoordinationTeam' do
    sequence(:name) { |n| "Team #{n}" }
    association :team_coordinator, factory: :user
    association :team_nurse_care_manager, factory: :user
  end
end
