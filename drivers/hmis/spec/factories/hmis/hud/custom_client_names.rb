###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_custom_client_name, class: 'Hmis::Hud::CustomClientName' do
    data_source { association :hmis_data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:CustomClientNameID) { |n| n + 100 }
    sequence(:first) { |n| ['Jim', 'Sue', 'Bob'][n % 3] }
    sequence(:last) { |n| ['Smith', 'Brown', 'Portman', 'Underwood', 'Jordan', 'White', 'Black'][n % 7] }
    NameDataQuality { 1 }
    after(:build) do |client_name|
      client_name.user ||= create(:hmis_hud_user, data_source: client_name.data_source)
    end
  end
end
