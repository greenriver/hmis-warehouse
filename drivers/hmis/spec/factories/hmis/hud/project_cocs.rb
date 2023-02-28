FactoryBot.define do
  factory :hmis_hud_project_coc, class: 'Hmis::Hud::ProjectCoc' do
    data_source { association :hmis_data_source }
    sequence(:ProjectCoCID, 200)
    project { association :hmis_hud_project }
    user { association :hmis_hud_user, data_source: data_source }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    CoCCode { 'XX-500' }
    Geocode { '123123' }
  end
end
