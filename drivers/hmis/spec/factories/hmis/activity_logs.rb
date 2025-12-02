###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_activity_log, class: 'Hmis::ActivityLog' do
    association :user, factory: :hmis_user
    association :data_source, factory: :grda_warehouse_data_source
    request_id { SecureRandom.uuid }
    ip_address { '127.0.0.1' }
  end
end
