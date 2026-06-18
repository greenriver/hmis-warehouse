###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :client_roi_authorization, class: 'GrdaWarehouse::ClientRoiAuthorization' do
    association :destination_client, factory: :grda_warehouse_hud_client
    status { 'full' }
  end
end
