FactoryBot.define do
  factory :grda_warehouse_hud_project, class: 'GrdaWarehouse::Hud::Project' do
    data_source_id { 1 } # :data_source_fixed_id
    sequence(:ProjectID, 200)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
