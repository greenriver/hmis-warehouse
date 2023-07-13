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
    wip { false }
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
    wip { true }
    AssessmentDate { Date.yesterday }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    transient do
      values { {} }
      hud_values { {} }
    end
    after(:create) do |assessment, evaluator|
      assessment.form_processor = create(:hmis_form_processor, custom_assessment: assessment, values: evaluator.values, hud_values: evaluator.hud_values)
      assessment.save_in_progress
    end
  end
end
