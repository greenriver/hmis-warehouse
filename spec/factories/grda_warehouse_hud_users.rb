FactoryBot.define do
  factory :hud_user, class: 'GrdaWarehouse::Hud::User' do
    sequence(:UserID, 5)
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 500)
  end
end
