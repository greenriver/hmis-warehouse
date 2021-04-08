FactoryBot.define do
  factory :vt_source_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :vt_source_data_source
    sequence(:PersonalID, 10)
  end

  factory :vt_destination_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :vt_destination_data_source
    sequence(:PersonalID, 10)
  end
end
