###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :default_course, class: 'Talentlms::Course' do
    default { true }
    name { 'Default Course' }
    association :config, factory: :talentlms_config
    sequence(:courseid) { |n| n }
  end
end
