FactoryBot.define do
  factory :vt_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    association :data_source, factory: :vt_source_data_source
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
  end
end
