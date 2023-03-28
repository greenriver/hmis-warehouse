FactoryBot.define do
  factory :hmis_disability, class: 'Hmis::Hud::Disability' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:DisabilitiesID, 500)
    disability_type { 7 }
    disability_response { 1 }
    information_date { Date.yesterday }
    data_collection_stage { 1 }
    DateCreated { Time.now }
    DateUpdated { Time.now }
  end
end
