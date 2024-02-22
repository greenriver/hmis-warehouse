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

  factory :hmis_project_auto_exit_config, class: 'Hmis::ProjectAutoExitConfig' do
    created_at { Date.parse('2019-01-01') }
    updated_at { Date.parse('2019-01-01') }
    config_options { { 'length_of_absence_days': 30 }.to_json }
  end
end
