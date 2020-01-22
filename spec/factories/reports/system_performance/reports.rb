FactoryBot.define do
  factory :spm_measure_one_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureOne' do
    name { 'SPM Measure One' }
  end

  factory :spm_measure_two_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureTwo' do
    name { 'SPM Measure Two' }
  end

  factory :spm_measure_three_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureThree' do
    name { 'SPM Measure Three' }
  end

  factory :spm_measure_four_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureFour' do
    name { 'SPM Measure Four' }
  end

  factory :spm_measure_five_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureFive' do
    name { 'SPM Measure Five' }
  end
end
