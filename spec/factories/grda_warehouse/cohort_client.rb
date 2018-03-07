FactoryGirl.define do
  factory :cohort_client, class: 'GrdaWarehouse::CohortClient' do
    adjusted_days_homeless 111
    rank 5
  end
end