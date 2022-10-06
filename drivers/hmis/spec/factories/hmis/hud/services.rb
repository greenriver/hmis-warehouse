FactoryBot.define do
  factory :hmis_hud_service, class: 'Hmis::Hud::Service' do
    association :data_source, factory: :hmis_data_source
    association :client, factory: :hmis_hud_client
    association :enrollment, factory: :hmis_hud_enrollment
    sequence(:ServicesID, 7)
    sequence(:UserID, 100)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    DateProvided { Date.today }
    RecordType { 200 }
    TypeProvided { 200 }
  end
end
