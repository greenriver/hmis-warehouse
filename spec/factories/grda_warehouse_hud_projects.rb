FactoryGirl.define do
  factory :hud_project, class: 'GrdaWarehouse::Hud::Project' do
    sequence(:ProjectName, 100) {|n| "Project #{n}"}
    sequence(:ProjectID, 100)
    sequence(:OrganizationID, 200)
  end
end
