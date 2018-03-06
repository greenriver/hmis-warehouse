FactoryGirl.define do
  factory :cohort, class: 'GrdaWarehouse::Cohort' do
    name 'Cohort 1'
    days_of_inactivity 90
    
  end
end