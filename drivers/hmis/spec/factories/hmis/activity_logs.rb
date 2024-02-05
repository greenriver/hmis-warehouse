###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_activity_log, class: 'Hmis::ActivityLog' do
    user { association :hmis_user }
    data_source { association :hmis_data_source }
    ip_address { '127.0.0.1' }
    variables { {} }
    operation_name { 'fakeTestOperation' }
    resolved_fields { {} }
  end
end
