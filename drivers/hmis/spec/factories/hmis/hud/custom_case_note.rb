###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_custom_case_note, class: 'Hmis::Hud::CustomCaseNote' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    content { 'test note' }
  end
end
