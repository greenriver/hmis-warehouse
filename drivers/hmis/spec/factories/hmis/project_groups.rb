###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_project_group, class: 'Hmis::ProjectGroup' do
    sequence(:name) { |n| "HMIS Project Group #{n}" }
    data_source { association :hmis_data_source }
    inclusion_criteria { {}.to_json } # no projects included
    exclusion_criteria { nil }
  end
end
