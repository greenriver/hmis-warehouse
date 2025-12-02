# frozen_string_literal: true

FactoryBot.define do
  factory :agency do
    sequence(:name) { |n| "Agency #{n}" }
  end
end
