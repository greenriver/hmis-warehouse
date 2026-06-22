###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :she_entry, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    association :client, factory: :hud_client
    data_source_id { client.data_source_id }
    record_type { :entry }
    date { Date.current }
    first_date_in_program { Date.current }
  end
  factory :she_exit, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    record_type { :exit }
  end
  factory :she_first, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    record_type { :first }
  end
end
