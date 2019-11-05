FactoryBot.define do
  factory :hud_enrollment_coc, class: 'GrdaWarehouse::Hud::EnrollmentCoc' do
    sequence(:EnrollmentCoCID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
    association :data_source, factory: :grda_warehouse_data_source
  end
end
