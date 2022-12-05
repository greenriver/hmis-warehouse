FactoryBot.define do
  factory :hmis_hud_event, class: 'Hmis::Hud::Event' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:EventID, 500)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    EventDate { Date.today }
    Event { 10 }
  end
end
