###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :synthetic_ce_assessment_project_config, class: 'SyntheticCeAssessment::ProjectConfig' do
    active { true }
  end
end
