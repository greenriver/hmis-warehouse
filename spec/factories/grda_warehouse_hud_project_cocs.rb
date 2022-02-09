FactoryBot.define do
  factory :hud_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
    sequence(:CoCCode) { |n| "XX-00#{n}" }
    association :data_source, factory: :source_data_source
  end
end
