# frozen_string_literal: true

FactoryBot.define do
  factory :rank, class: 'CohortColumns::Rank' do
    cohort_column_type { create(:cohort_column_type, class_name: 'CohortColumns::Rank') }
  end
end
