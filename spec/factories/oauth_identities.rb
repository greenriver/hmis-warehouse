###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_identity do
    provider { 'wh_okta' }
    sequence(:uid) { |n| "uid-#{n}" }
    association :user
  end
end
