FactoryBot.define do
  factory :vt_enrollment_coc, class: 'GrdaWarehouse::Hud::EnrollmentCoc' do
    association :data_source, factory: :vt_source_data_source
    sequence(:EnrollmentCoCID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:ProjectID, 100)
    sequence(:PersonalID, 10)
  end
end
