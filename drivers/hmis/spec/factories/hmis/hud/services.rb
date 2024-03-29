###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_service, class: 'Hmis::Hud::Service', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:ServicesID, 500)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    DateProvided { Date.yesterday }
    RecordType { 200 }
    TypeProvided { 200 }
  end
end
