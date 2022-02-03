###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_user, class: 'User' do
    first_name { 'Green' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    password { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    password_confirmation { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
  end
end
