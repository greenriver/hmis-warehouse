FactoryGirl.define do
  factory :data_quality_report_base, class: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree' do
    completed_at { Time.now }
    start { Date.parse('2015-01-01') }
    add_attribute(:end) { Date.today }
  end

  trait :single_project do
    project { GrdaWarehouse::Hud::Project.first }
  end

  factory :dq_project_group, class: 'GrdaWarehouse::ProjectGroup' do
    name 'project group'
    projects { GrdaWarehouse::Hud::Project.all }
  end

  trait :project_group do
    association :project_group, factory: :dq_project_group
  end

end