FactoryBot.define do
  factory :hmis_enrollment_coc, class: 'Hmis::Hud::EnrollmentCoc' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:EnrollmentCoCID, 500)
    information_date { Date.today }
    coc_code { 'XX-500' }
    data_collection_stage { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
