###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :talentlms_config, class: 'Talentlms::Config' do
    sequence(:subdomain) { |n| "training#{n}" }
    api_key { 'test_key' }
  end
end
