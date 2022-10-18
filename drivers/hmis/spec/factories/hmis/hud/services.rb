FactoryBot.define do
  factory :hmis_hud_service, class: 'Hmis::Hud::Service' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:ServicesID, 7)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    DateProvided { Date.today }
    RecordType { 200 }
    TypeProvided { 200 }
  end
end
