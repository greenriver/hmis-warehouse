# frozen_string_literal: true

FactoryBot.define do
  factory :cohort_column, class: 'GrdaWarehouse::Cohorts::CohortColumn' do
    sequence(:class_name) { |n| "CohortColumns::UserString#{n}" }
    active { true }
  end
end
