FactoryBot.define do
  factory :hud_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :grda_warehouse_data_source
    sequence(:PersonalID, 10)
  end
end
