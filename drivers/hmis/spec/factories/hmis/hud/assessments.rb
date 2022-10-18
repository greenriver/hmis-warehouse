FactoryBot.define do
  factory :hmis_hud_assessment, class: 'Hmis::Hud::Assessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
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
