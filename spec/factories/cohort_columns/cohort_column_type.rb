# frozen_string_literal: true

FactoryBot.define do
  factory :cohort_column_type, class: 'GrdaWarehouse::CohortColumnType' do
    class_name { 'CohortColumns::UserString1' }
    active { true }
  end
end
