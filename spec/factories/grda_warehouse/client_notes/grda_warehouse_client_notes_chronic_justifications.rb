###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_client_notes_chronic_justification, class: 'GrdaWarehouse::ClientNotes::ChronicJustification' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note { 'Test' }
    type { 'GrdaWarehouse::ClientNotes::ChronicJustification' }
  end
end
