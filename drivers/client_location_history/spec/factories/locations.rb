###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
