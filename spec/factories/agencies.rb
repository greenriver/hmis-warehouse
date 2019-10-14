FactoryBot.define do
  factory :agency do
    sequence(:name) { |n| "Agency #{n}" }
  end
end
