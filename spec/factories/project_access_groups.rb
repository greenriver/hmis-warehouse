###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :project_access_group, class: 'GrdaWarehouse::ProjectAccessGroup' do
    sequence(:name) { |n| "Project Group #{n}" }
    skip_maintain_system_group { true } # Default to true

    trait :with_maintain do
      skip_maintain_system_group { false }
    end
  end
end
