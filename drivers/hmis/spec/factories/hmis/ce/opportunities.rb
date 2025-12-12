# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_opportunity, class: 'Hmis::Ce::Opportunity' do
    sequence(:name) { |n| "Opportunity #{n}" }
    status { 'open' }
    unit { association :hmis_unit }
  end
end
