FactoryBot.define do
  factory :collection do
    sequence(:name) { |n| "Collection #{n}" }
  end
end
