# frozen_string_literal: true

FactoryBot.define do
  factory :date_added_to_cohort, class: 'CohortColumns::DateAddedToCohort' do
    cohort_column_type { GrdaWarehouse::CohortColumnType.find_by(class_name: 'CohortColumns::DateAddedToCohort') }
  end
end
