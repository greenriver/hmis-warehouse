###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_processor, class: 'Hmis::Form::FormProcessor' do
    definition { association :hmis_form_definition }
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
    transient do
      values { {} }
      hud_values { {} }
      definition { nil }
    end
    after(:build) do |assessment, evaluator|
      assessment.form_processor = build(:hmis_form_processor, owner: assessment, values: evaluator.values, hud_values: evaluator.hud_values)
      assessment.form_processor.definition = evaluator.definition if evaluator.definition
      assessment.data_collection_stage = Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[evaluator.definition.role.to_sym] if evaluator.definition
    end
    after(:create) do |assessment, evaluator|
      assessment.build_form_processor(values: evaluator.values, hud_values: evaluator.hud_values, definition: evaluator.definition)
      assessment.form_processor.definition ||= build(:hmis_form_definition)
      assessment.data_collection_stage = Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[evaluator.definition.role.to_sym] if evaluator.definition
      assessment.save!
    end
  end

  factory :hmis_intake_assessment, parent: :hmis_custom_assessment do
    DataCollectionStage { 1 }
    # transient do
    #   definition { build(:hmis_intake_assessment_definition) }
    # end
    after(:create) do |assessment, _evaluator|
      assessment.update!(assessment_date: assessment.enrollment.entry_date)
      assessment.update!(date_created: assessment.enrollment.date_created)
      assessment.update!(date_updated: assessment.enrollment.date_updated)
    end
  end

  factory :hmis_wip_custom_assessment, parent: :hmis_custom_assessment do
    wip { true }
  end
end
