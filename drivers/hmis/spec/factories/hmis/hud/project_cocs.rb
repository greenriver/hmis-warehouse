FactoryBot.define do
  factory :hmis_hud_project_coc, class: 'Hmis::Hud::ProjectCoc' do
    association :data_source, factory: :hmis_data_source
    sequence(:ProjectCoCID, 200)
    sequence(:ProjectID, 200)
    sequence(:UserID, 100)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    CoCCode { 'XX-500' }
    Geocode { '123123' }
  end
end
