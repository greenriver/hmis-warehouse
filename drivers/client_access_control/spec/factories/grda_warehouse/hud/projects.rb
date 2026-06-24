###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :vt_project, class: 'GrdaWarehouse::Hud::Project' do
    association :data_source, factory: :vt_source_data_source
    sequence(:ProjectName, 100) { |n| "Project #{n}" }
    sequence(:ProjectID, 100)
    sequence(:OrganizationID, 200)
    ProjectType { ::HudHelper.util.project_types.keys.sample }
  end
end
