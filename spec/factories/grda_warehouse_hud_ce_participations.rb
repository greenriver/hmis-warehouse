FactoryBot.define do
  factory :hud_ce_participation, class: 'GrdaWarehouse::Hud::CeParticipation' do
    association :data_source, factory: :grda_warehouse_data_source
    sequence(:ProjectID, 100)
    sequence(:CEParticipationID, 1)
    AccessPoint { 1 }
    CEParticipationStatusStartDate { 1.year.ago }
    DateCreated { 1.year.ago }
    DateUpdated { 1.year.ago }
    sequence(:UserID, 5)
    sequence(:ExportID, 500)
  end
end
