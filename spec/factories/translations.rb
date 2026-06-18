###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :translation do
    key { "key.#{SecureRandom.hex}" }
    text { 'text for key' }
  end
end
