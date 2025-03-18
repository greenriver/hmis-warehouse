# frozen_string_literal: true

FactoryBot.define do
  factory :hud_project, class: 'GrdaWarehouse::Hud::Project' do
    data_source { association :grda_warehouse_data_source }
    sequence(:ProjectName, 100) { |n| "Project #{n}" }
    sequence(:ProjectID, 100)
    sequence(:OrganizationID, 200)
    ProjectType { ::HudUtility2024.project_types.keys.sample }
  end
end
