###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_assessment_question, class: 'Hmis::Hud::AssessmentQuestion' do
    sequence(:AssessmentQuestionID, 500)
    data_source { association :hmis_data_source }
    assessment { association :hmis_hud_assessment, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    assessment_question { 'Question?' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
