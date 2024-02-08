###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_health_and_dv, class: 'Hmis::Hud::HealthAndDv' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:HealthAndDVID, 500)
    information_date { Date.yesterday }
    data_collection_stage { 1 }
    DateCreated { Time.now }
    DateUpdated { Time.now }
  end
end
