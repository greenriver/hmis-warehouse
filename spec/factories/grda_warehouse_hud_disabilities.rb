FactoryGirl.define do
  factory :hud_disability, class: 'GrdaWarehouse::Hud::Disability' do
    sequence(:DisabilitiesID, 5)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
  end
end
