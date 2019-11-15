FactoryBot.define do
  factory :access_group do
    sequence(:name) { |n| "Group #{n}" }
  end
end
