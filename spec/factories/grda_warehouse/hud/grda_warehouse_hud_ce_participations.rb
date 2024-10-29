FactoryBot.define do
  factory :grda_warehouse_hud_ce_participation, class: 'GrdaWarehouse::Hud::CeParticipation' do
    data_source_id { 1 } # :data_source_fixed_id
    sequence(:CEParticipationID, 200)
    sequence(:ProjectID, 200)
    DateCreated { Date.parse('2023-01-01') }
    DateUpdated { Date.parse('2023-01-01') }
  end
end
