FactoryBot.define do
  factory :spm_measure_one_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureOne' do
    name { 'SPM Measure One' }
  end

  factory :spm_measure_two_fy2019, class: 'Reports::SystemPerformance::Fy2019::MeasureTwo' do
    name { 'SPM Measure Two' }
  end
end
