###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_assessment_question, class: 'Hmis::Hud::AssessmentQuestion', parent: :hmis_base_factory do
    sequence(:AssessmentQuestionID, 500)
    assessment { association :hmis_hud_assessment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    assessment_question { 'Question?' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    enrollment_slug { "#{enrollment_id}:#{personal_id}:#{data_source_id}" }
  end
end
