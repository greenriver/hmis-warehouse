###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_ce_participation, class: 'Hmis::Hud::CeParticipation' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    project { association :hmis_hud_project, data_source: data_source }
    sequence(:CEParticipationID, 300)
    AccessPoint { 0 }
    CEParticipationStatusStartDate { '2020-12-01' }
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 1)
  end
end
