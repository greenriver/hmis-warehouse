###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :inbound_api_configuration, class: 'HmisExternalApis::InboundApiConfiguration' do
    internal_system
    sequence(:external_system_name) { |n| ['LINK', 'MPER', 'AABB', 'QQRR', 'AAAA'][n % 5] }
  end
end
