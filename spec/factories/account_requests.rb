###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :account_request do
    sequence(:email) { |n| "requester#{n}@example.com" }
    first_name { 'Reqmond' }
    last_name { 'Ester' }
    details { 'Please give me access to the warehouse.' }
    status { :requested }

    # The :create email validation does an MX lookup (check_mx: true), skip validation to avoid it
    to_create { |instance| instance.save(validate: false) }
  end
end
