# frozen_string_literal: true

FactoryBot.define do
  factory :access_group do
    sequence(:name) { |n| "Access Group #{n}" }
  end
end
