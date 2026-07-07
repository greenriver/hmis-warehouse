###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :app_config_property do
    sequence(:key) { |n| "config_key_#{n}" }
    sequence(:value) { |n| { 'value' => "config_value_#{n}" } }
  end
end
