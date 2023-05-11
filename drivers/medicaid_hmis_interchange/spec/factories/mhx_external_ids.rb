FactoryBot.define do
  factory :mhx_external_id, class: 'MedicaidHmisInterchange::Health::ExternalId' do
    association :client, factory: :grda_warehouse_hud_client
    sequence(:identifier, 1000000)
    valid_id { true }
  end
end
