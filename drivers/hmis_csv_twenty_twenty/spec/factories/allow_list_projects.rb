FactoryBot.define do
  factory :allowed_project, class: 'GrdaWarehouse::WhitelistedProjectsForClients' do
    project_id { 'ALLOW' }
  end
end
