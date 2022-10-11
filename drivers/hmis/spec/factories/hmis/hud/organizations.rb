FactoryBot.define do
  factory :hmis_hud_organization, class: 'Hmis::Hud::Organization' do
    association :data_source, factory: :hmis_data_source
    sequence(:OrganizationID, 200)
    OrganizationName { 'Organization' }
    VictimServiceProvider { false }
    sequence(:UserID, 100)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
