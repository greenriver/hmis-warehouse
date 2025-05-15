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

    transient do
      including_entire_data_source { nil }
    end
    after(:create) do |instance, evaluator|
      if evaluator.including_entire_data_source
        instance.inclusion_criteria = { data_source_ids: [instance.data_source_id] }.to_json
        instance.save!
      end
      instance.maintain_projects!
    end
  end
end
