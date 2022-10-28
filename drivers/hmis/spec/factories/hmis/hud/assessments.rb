FactoryBot.define do
  factory :hmis_hud_assessment, class: 'Hmis::Hud::Assessment' do
    association :enrollment, factory: :hmis_hud_enrollment
    association :client, factory: :hmis_hud_client
    association :user, factory: :hmis_hud_user
    sequence(:AssessmentID, 1)
    AssessmentDate { Date.parse('2019-01-01') }
    AssessmentLocation { 'Test Location' }
    AssessmentType { 1 }
    AssessmentLevel { 1 }
    PrioritizationStatus { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
