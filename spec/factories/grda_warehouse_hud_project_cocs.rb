FactoryBot.define do
  factory :hud_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
    association :data_source, factory: :grda_warehouse_data_source
  end
end
