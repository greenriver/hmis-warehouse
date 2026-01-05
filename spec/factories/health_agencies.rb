# frozen_string_literal: true

FactoryBot.define do
  factory :health_agency, class: 'Health::Agency' do
    sequence(:name) { |n| "Agency #{n}" }
  end
end
