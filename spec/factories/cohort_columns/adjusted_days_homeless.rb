# frozen_string_literal: true

FactoryBot.define do
  factory :adjusted_days_homeless, class: 'CohortColumns::AdjustedDaysHomeless' do
    cohort_column { GrdaWarehouse::Cohorts::CohortColumn.find_by(class_name: 'CohortColumns::AdjustedDaysHomeless') }
  end
end
