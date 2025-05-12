###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :synthetic_ce_assessment_project_config, class: 'SyntheticCeAssessment::ProjectConfig' do
    active { true }
  end
end
