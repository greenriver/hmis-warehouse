# frozen_string_literal: true

FactoryBot.define do
  factory :login_activity do
    association :user
    user_type { 'User' }
    scope { 'user' }
    success { true }
    strategy { 'password' }

    trait :failed do
      success { false }
    end
  end
end
