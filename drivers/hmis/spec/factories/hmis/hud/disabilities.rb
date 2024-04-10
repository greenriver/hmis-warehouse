###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_disability, class: 'Hmis::Hud::Disability', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:DisabilitiesID, 500)
    disability_type { 7 }
    disability_response { 1 }
    information_date { Date.yesterday }
    data_collection_stage { 1 }
  end
end
