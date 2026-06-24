###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :project_group, class: 'GrdaWarehouse::ProjectGroup' do
    sequence(:name) { |n| "project-group#{n}" }
  end
end
