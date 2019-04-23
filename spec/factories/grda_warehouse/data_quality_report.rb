FactoryBot.define do
  factory :data_quality_report_version_three, class: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree' do
    completed_at { Time.now }
    start { '2016-01-01'.to_date }
    add_attribute(:end) { '2016-12-31'.to_date }
  end

  trait :single_project do
    project { GrdaWarehouse::Hud::Project.first }
  end

  factory :dq_project_group, class: 'GrdaWarehouse::ProjectGroup' do
    name { 'project group' }
    projects { GrdaWarehouse::Hud::Project.all }
  end

  trait :project_group do
    association :project_group, factory: :dq_project_group
  end
end
