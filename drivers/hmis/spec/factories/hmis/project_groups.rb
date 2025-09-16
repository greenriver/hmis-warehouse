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
      with_projects { [] } # projects to include in the group. overrides inclusion_criteria
    end
    after(:create) do |instance, evaluator|
      # Add projects to the group if specified
      if evaluator.with_projects.present?
        instance.inclusion_criteria = {
          project_ids: evaluator.with_projects.map(&:id).map(&:to_s),
        }.to_json
        instance.save!
      end

      # Maintain project group to populate `project_groups.projects` association
      instance.maintain_projects!
    end
  end
end
