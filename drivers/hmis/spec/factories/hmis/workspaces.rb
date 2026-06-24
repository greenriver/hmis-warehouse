###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workspace, class: 'Hmis::Workspace' do
    association :data_source, factory: :hmis_data_source
    project_group { association :hmis_project_group, data_source: data_source }
    sequence(:name) { |n| "HMIS Workspace #{n}" }
    sequence(:slug) { |n| "hmis-workspace-#{n}" }
    applies_to { Hmis::Workspace::CE_REFERRALS }
    sequence(:sort_order)
    active { true }
  end
end
