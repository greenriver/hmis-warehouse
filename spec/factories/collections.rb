# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    sequence(:name) { |n| "Collection #{n}" }
    collection_type { 'Projects' }
  end
end
