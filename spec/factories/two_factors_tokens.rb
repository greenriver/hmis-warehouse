FactoryBot.define do
  factory :two_factors_token do
    user { nil }
    guid { 'MyString' }
    device { 'MyString' }
  end
end
