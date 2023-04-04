###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_organization, class: 'Hmis::Hud::Organization' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    sequence(:OrganizationID, 200)
    OrganizationName { 'Organization' }
    VictimServiceProvider { false }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
