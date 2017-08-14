FactoryGirl.define do
  factory :missing_grade_a, class: 'GrdaWarehouse::Grades::Missing' do
    grade 'A'
    percentage_low 0
    percentage_high 5
  end

  factory :missing_grade_b, class: 'GrdaWarehouse::Grades::Missing' do
    grade 'B'
    percentage_low 6
    percentage_high 10
  end

end
