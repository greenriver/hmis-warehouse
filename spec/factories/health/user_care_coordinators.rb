# frozen_string_literal: true

FactoryBot.define do
  factory :user_care_coordinator, class: 'Health::UserCareCoordinator' do
    association :user, factory: :user
    association :coordination_team, factory: :coordination_team
  end
end
