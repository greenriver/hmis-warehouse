FactoryGirl.define do
  factory :utilization_grade_a, class: 'GrdaWarehouse::Grades::Utilization' do
    grade 'A'
    percentage_under_low 95
    percentage_under_high 100
    percentage_over_low 101
    percentage_over_high 105
  end

  factory :utilization_grade_b, class: 'GrdaWarehouse::Grades::Utilization' do
    grade 'B'
    percentage_under_low 90
    percentage_under_high 94
    percentage_over_low 106
    percentage_over_high 110
  end

  factory :utilization_grade_f, class: 'GrdaWarehouse::Grades::Utilization' do
    grade 'F'
    percentage_under_low 0
    percentage_under_high 64
    percentage_over_low 136
    percentage_over_high nil
  end
end
