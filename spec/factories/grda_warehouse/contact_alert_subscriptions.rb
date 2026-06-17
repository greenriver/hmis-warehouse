###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :contact_alert_subscription, class: 'GrdaWarehouse::ContactAlertSubscription' do
    association :contact, factory: :grda_warehouse_contact_user
    association :alert_definition
    active { true }
  end
end
