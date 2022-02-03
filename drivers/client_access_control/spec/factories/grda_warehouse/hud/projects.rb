###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_project, class: 'GrdaWarehouse::Hud::Project' do
    association :data_source, factory: :vt_source_data_source
    sequence(:ProjectName, 100) { |n| "Project #{n}" }
    sequence(:ProjectID, 100)
    sequence(:OrganizationID, 200)
    ProjectType { ::HUD.project_types.keys.sample }
  end
end
