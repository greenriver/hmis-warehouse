###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :mhx_external_id, class: 'MedicaidHmisInterchange::Health::ExternalId' do
    association :client, factory: :grda_warehouse_hud_client
    sequence(:identifier, 1000000)
  end
end
