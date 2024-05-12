###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_current_living_situation, class: 'Hmis::Hud::CurrentLivingSituation', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:CurrentLivingSitID, 500)
    information_date { Date.yesterday }
    current_living_situation { 1 }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    enrollment_slug { "#{enrollment_id}:#{personal_id}:#{data_source_id}" }
  end
end
