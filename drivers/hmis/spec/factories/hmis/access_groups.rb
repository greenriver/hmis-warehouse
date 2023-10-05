###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
    transient do
      # helper to set group viewable entities. can be projects, orgs, or data sources.
      with_entities { nil }
    end
    after(:create) do |group, evaluator|
      if evaluator.with_entities.present?
        Array.wrap(evaluator.with_entities).each do |entity|
          group.add_viewable(entity)
        end
      end
    end
  end
end
