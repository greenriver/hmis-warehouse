###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_custom_service, class: 'Hmis::Hud::CustomService' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    custom_service_type { association :hmis_custom_service_type, data_source: data_source }
    sequence(:CustomServiceID, 500)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    DateProvided { Date.parse('2019-01-01') }
    transient do
      definition { nil }
    end
    after(:create) do |service, evaluator|
      next unless evaluator.definition

      service.form_processor = create(:hmis_form_processor, owner: service, definition: evaluator.definition)
    end
  end
end
