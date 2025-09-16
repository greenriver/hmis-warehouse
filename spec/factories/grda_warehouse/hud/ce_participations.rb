###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  factory :grda_warehouse_hud_ce_participation, class: 'GrdaWarehouse::Hud::CeParticipation' do
    data_source_id { 1 } # :data_source_fixed_id
    sequence(:CEParticipationID, 200)
    sequence(:ProjectID, 200)
    DateCreated { Date.parse('2023-01-01') }
    DateUpdated { Date.parse('2023-01-01') }
  end
end
