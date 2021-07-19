FactoryBot.define do
  factory :cohort, class: 'GrdaWarehouse::Cohort' do
    name { 'Cohort 1' }
    days_of_inactivity { 90 }
  end

  factory :currently_homeless_cohort, class: 'GrdaWarehouse::SystemCohorts::CurrentlyHomeless' do
    name { 'Currently Homeless' }
    days_of_inactivity { 90 }
  end
end
