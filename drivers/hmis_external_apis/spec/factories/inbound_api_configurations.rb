###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :inbound_api_configuration, class: 'HmisExternalApis::InboundApiConfiguration' do
    internal_system
    sequence(:external_system_name) { |n| ['LINK', 'MPER', 'AABB', 'QQRR', 'AAAA'][n % 5] }
  end
end
