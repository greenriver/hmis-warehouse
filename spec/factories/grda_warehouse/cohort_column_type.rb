# frozen_string_literal: true

FactoryBot.define do
  factory :cohort_column_type, class: 'GrdaWarehouse::CohortColumnType' do
    sequence(:class_name) { |n| "CohortColumns::UserString#{n}" }
    active { true }
  end
end
