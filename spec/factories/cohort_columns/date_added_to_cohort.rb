# frozen_string_literal: true

FactoryBot.define do
  factory :date_added_to_cohort, class: 'CohortColumns::DateAddedToCohort' do
    column_type { create(:cohort_column_type, class_name: 'CohortColumns::DateAddedToCohort') }
  end
end
