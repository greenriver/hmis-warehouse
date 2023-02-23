FactoryBot.define do
  factory :hmis_current_living_situation, class: 'Hmis::Hud::CurrentLivingSituation' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:CurrentLivingSitID, 500)
    information_date { Date.today }
    current_living_situation { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
