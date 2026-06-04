###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :vt_user, class: 'User' do
    first_name { 'Green' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
  end
end
