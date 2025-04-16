# frozen_string_literal: true

FactoryBot.define do
  1..30.times do |i|
    name = "user_string_cohort_column_#{i}"
    factory name.to_sym, class: "CohortColumns::UserString#{i}" do
      column_type { create(:cohort_column_type, class_name: "CohortColumns::UserString#{i}") }
    end
  end
end
