FactoryBot.define do
  factory :hmis_hud_assessment, class: 'Hmis::Hud::Assessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:AssessmentID, 500)
    AssessmentDate { Date.parse('2019-01-01') }
    AssessmentLocation { 'Test Location' }
    AssessmentType { 1 }
    AssessmentLevel { 1 }
    PrioritizationStatus { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end

  factory :hmis_hud_assessment_with_defaults, class: 'Hmis::Hud::Assessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:AssessmentID, 500)
    AssessmentDate { Date.parse('2019-01-01') }
    AssessmentLocation { 'Test Location' }
    AssessmentType { 1 }
    AssessmentLevel { 1 }
    PrioritizationStatus { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }

    initialize_with do
      Hmis::Hud::Assessment.new_with_defaults(
        enrollment: enrollment,
        user: enrollment.user,
        form_definition: create(:hmis_form_definition),
        assessment_date: Date.current,
      )
    end
  end
end
