FactoryBot.define do
  factory :oauth_identity do
    provider { 'wh_okta' }
    sequence(:uid) { |n| "uid-#{n}" }
    association :user
  end
end
