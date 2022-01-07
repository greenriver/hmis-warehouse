FactoryBot.define do
  factory :hud_enrollment_coc, class: 'GrdaWarehouse::Hud::EnrollmentCoc' do
    sequence(:EnrollmentCoCID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:ProjectID, 100)
    sequence(:PersonalID, 10)
    sequence(:CoCCode) { |n| "XX-00#{n}" }
    association :data_source, factory: :source_data_source
  end
end
