FactoryBot.define do
  factory :hmis_hud_funder, class: 'Hmis::Hud::Funder' do
    data_source { association :hmis_data_source }
    sequence(:FunderID, 300)
    sequence(:ProjectID, 200)
    sequence(:UserID, 100)
    GrantID { 'grant id' }
    Funder { 20 }
    StartDate { '2020-12-01' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
