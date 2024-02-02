###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_custom_client_address, class: 'Hmis::Hud::CustomClientAddress' do
    data_source { association :hmis_data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:AddressID) { |n| n + 100 }

    use { 'home' }
    address_type { 'postal' }
    sequence(:line1) { |n| "#{n + 123} Test St" }
    line2 { 'Apt 0' }
    city { 'Nowhere' }
    sequence(:state) { |n| ['KS', 'VT'][n % 2] }
    sequence(:postal_code) { |n| (n + 50000).to_s[0..5] }

    after(:build) do |address|
      address.user ||= create(:hmis_hud_user, data_source: address.data_source)
    end
  end

  factory :hmis_move_in_address, parent: :hmis_hud_custom_client_address do
    enrollment { association :hmis_hud_enrollment, data_source: data_source }
    enrollment_address_type { 'move_in' }
  end
end
