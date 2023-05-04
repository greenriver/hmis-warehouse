###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_custom_client_contact_point, class: 'Hmis::Hud::CustomClientContactPoint' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    sequence(:ContactPointID, 100)

    use { 'home' }
    system { 'phone' }
    value { '5554567890' }
  end
end
