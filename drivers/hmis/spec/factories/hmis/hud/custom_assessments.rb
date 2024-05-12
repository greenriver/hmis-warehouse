###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    wip { false }
    AssessmentDate { Date.yesterday }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    enrollment_slug { "#{enrollment_id}:#{personal_id}:#{data_source_id}" }
    transient do
      values { {} }
      hud_values { {} }
      definition { nil }
    end
    after(:build) do |assessment, evaluator|
      assessment.form_processor = build(:hmis_form_processor, custom_assessment: assessment, values: evaluator.values, hud_values: evaluator.hud_values)
      assessment.form_processor.definition = evaluator.definition if evaluator.definition
    end
    after(:create) do |assessment, evaluator|
      assessment.build_form_processor(values: evaluator.values, hud_values: evaluator.hud_values, definition: evaluator.definition)
      assessment.form_processor.definition ||= build(:hmis_form_definition)
      assessment.save!
    end
  end

  factory :hmis_wip_custom_assessment, class: 'Hmis::Hud::CustomAssessment' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    wip { true }
    AssessmentDate { Date.yesterday }
    DataCollectionStage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    enrollment_slug { "#{enrollment_id}:#{personal_id}:#{data_source_id}" }
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
