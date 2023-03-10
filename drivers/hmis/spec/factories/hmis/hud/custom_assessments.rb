FactoryBot.define do
  factory :hmis_custom_assessment, class: 'Hmis::Hud::CustomAssessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    AssessmentDate { Date.parse('2019-01-01') }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end

  factory :hmis_custom_assessment_with_defaults, class: 'Hmis::Hud::CustomAssessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    initialize_with do
      Hmis::Hud::CustomAssessment.new_with_defaults(
        enrollment: enrollment,
        user: enrollment.user,
        form_definition: create(:hmis_form_definition),
        assessment_date: Date.parse('2019-01-01'),
      )
    end
  end
end
