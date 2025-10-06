# frozen_string_literal: true

FactoryBot.define do
  factory :access_group_member do
    association :access_group
    association :user
  end
end
