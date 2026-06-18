###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :alert_definition, class: 'GrdaWarehouse::AlertDefinition' do
    sequence(:code) { |n| "alert_code_#{n}" }
    sequence(:name) { |n| "Alert Name #{n}" }
    category { 'system' }
    description { 'Test alert definition' }
    active { true }
  end
end
