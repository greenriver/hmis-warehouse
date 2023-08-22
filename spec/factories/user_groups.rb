FactoryBot.define do
  factory :user_group do
    sequence(:name) { |n| "Group #{n}" }
  end
end
