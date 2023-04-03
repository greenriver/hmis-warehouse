###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_funder, class: 'Hmis::Hud::Funder' do
    data_source { association :hmis_data_source }
    sequence(:FunderID, 300)
    project { association :hmis_hud_project, data_source: data_source }
    user { association :hmis_hud_user, data_source: data_source }
    GrantID { 'grant id' }
    Funder { 20 }
    StartDate { '2020-12-01' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
