FactoryBot.define do
  factory :hmis_assessment_result, class: 'Hmis::Hud::AssessmentResult' do
    sequence(:AssessmentResultID, 500)
    data_source { association :hmis_data_source }
    assessment { association :hmis_hud_assessment, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    assessment_result_type { 'Result Type' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
