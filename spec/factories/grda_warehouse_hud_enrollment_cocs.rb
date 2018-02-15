FactoryGirl.define do
  factory :hud_enrollment_coc, class: 'GrdaWarehouse::Hud::EnrollmentCoc' do
    sequence(:EnrollmentCoCID, 7)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
  end
end
