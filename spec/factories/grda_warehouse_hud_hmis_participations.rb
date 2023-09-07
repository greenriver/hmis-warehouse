FactoryBot.define do
  factory :hud_hmis_participation, class: 'GrdaWarehouse::Hud::HmisParticipation' do
    association :data_source, factory: :grda_warehouse_data_source
    sequence(:ProjectID, 100)
    sequence(:HMISParticipationID, 1)
    HMISParticipationType { 1 }
    HMISParticipationStatusStartDate { 1.year.ago }
    DateCreated { 1.year.ago }
    DateUpdated { 1.year.ago }
    sequence(:UserID, 5)
    sequence(:ExportID, 500)
  end
end
