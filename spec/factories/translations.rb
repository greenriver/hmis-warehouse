# frozen_string_literal: true

FactoryBot.define do
  factory :translation do
    key { "key.#{SecureRandom.hex}" }
    text { 'text for key' }
  end
end
