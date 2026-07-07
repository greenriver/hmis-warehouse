###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :talentlms_login, class: 'Talentlms::Login' do
    lms_user_id { 1 }
    association :user
    association :config, factory: :talentlms_config
  end
end
