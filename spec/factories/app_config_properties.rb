###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :app_config_property do
    sequence(:key) { |n| "config_key_#{n}" }
    sequence(:value) { |n| "config_value_#{n}" }
  end
end
