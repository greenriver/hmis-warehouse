###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :recurring_hmis_export_link, class: 'GrdaWarehouse::RecurringHmisExportLink' do
    association :recurring_hmis_export
    association :hmis_export, factory: :grda_warehouse_hmis_export
    exported_at { Date.current }
  end
end
