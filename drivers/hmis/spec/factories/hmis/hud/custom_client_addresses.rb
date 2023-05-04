###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_custom_client_address, class: 'Hmis::Hud::CustomClientAddress' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:AddressID, 100)

    use { 'home' }
    address_type { 'postal' }
    line1 { '123 Test St' }
    line2 { 'Apt 0' }
    city { 'Nowhere' }
    state { 'XX' }
  end
end
