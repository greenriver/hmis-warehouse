###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :mhx_external_id, class: 'MedicaidHmisInterchange::Health::ExternalId' do
    association :client, factory: :grda_warehouse_hud_client
    sequence(:identifier, 1000000)
  end
end
