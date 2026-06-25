###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :clh_location, class: 'ClientLocationHistory::Location' do
    # source
    # client_id
    # enrollment_id
    lat { Faker::Address.latitude }
    lon { Faker::Address.longitude }
    collected_by { 'Fake Project Name' }
    located_on { Date.current }
  end
end
