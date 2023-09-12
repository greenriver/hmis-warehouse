FactoryBot.define do
  factory :access_group do
    sequence(:name) { |n| "Access Group #{n}" }
  end
end
