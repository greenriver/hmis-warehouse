FactoryBot.define do
  factory :hmis_hud_project, class: 'Hmis::Hud::Project' do
    association :data_source, factory: :hmis_data_source
    sequence(:ProjectID, 200)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
