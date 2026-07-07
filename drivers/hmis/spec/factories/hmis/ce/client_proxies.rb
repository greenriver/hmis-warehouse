###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_client_proxy, class: 'Hmis::Ce::ClientProxy' do
    association :client, factory: :grda_warehouse_hud_client
    client_type { 'GrdaWarehouse::Hud::Client' } # Ensure this matches the actual class name
  end
end
