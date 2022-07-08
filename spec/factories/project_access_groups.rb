FactoryBot.define do
  factory :project_access_group, class: 'GrdaWarehouse::ProjectAccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
  end
end
