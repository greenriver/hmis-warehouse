###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_project_auto_enter_config, class: 'Hmis::ProjectAutoEnterConfig' do
    created_at { Date.parse('2019-01-01') }
    updated_at { Date.parse('2019-01-01') }
  end
end
