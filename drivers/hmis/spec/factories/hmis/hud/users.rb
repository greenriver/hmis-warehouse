FactoryBot.define do
  factory :hmis_hud_user, class: 'Hmis::Hud::User' do
    data_source { association :hmis_data_source }
    sequence(:UserID, 500)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 1)
  end
end
