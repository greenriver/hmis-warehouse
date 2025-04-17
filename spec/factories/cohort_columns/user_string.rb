# frozen_string_literal: true

FactoryBot.define do
  1..30.times do |i|
    name = "user_string_cohort_column_#{i}"
    factory name.to_sym, class: "CohortColumns::UserString#{i}" do
      cohort_column_type { GrdaWarehouse::CohortColumnType.find_by(class_name: "CohortColumns::UserString#{i}") }
    end
  end
end
