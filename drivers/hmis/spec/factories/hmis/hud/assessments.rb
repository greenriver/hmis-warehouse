###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_hud_assessment, class: 'Hmis::Hud::Assessment', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:AssessmentID, 500)
    AssessmentDate { Date.parse('2019-01-01') }
    AssessmentLocation { 'Test Location' }
    AssessmentType { 1 }
    AssessmentLevel { 1 }
    PrioritizationStatus { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
