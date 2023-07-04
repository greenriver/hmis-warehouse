###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_processor, class: 'Hmis::Form::FormProcessor' do
    definition { association :hmis_form_definition }
    custom_assessment { association :hmis_custom_assessment }
  end

  factory :hmis_custom_assessment, class: 'Hmis::Hud::CustomAssessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    AssessmentDate { Date.yesterday }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    after(:create) do |assessment|
      assessment.form_processor = create(:hmis_form_processor, custom_assessment: assessment)
    end
  end

  factory :hmis_wip_custom_assessment, class: 'Hmis::Hud::CustomAssessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    AssessmentDate { Date.yesterday }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    after(:create) do |assessment|
      assessment.form_processor = create(:hmis_form_processor, custom_assessment: assessment, values: {}, hud_values: {})
      assessment.build_wip(
        enrollment: assessment.enrollment,
        client: assessment.enrollment.client,
        date: assessment.assessment_date,
      )
      assessment.save_in_progress
    end
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
        assessment_date: enrollment.entry_date.strftime('%Y-%m-%d'),
      )
    end
  end
end
