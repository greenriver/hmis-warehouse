###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_scan_card_code, class: 'Hmis::ScanCardCode' do
    client { association :hmis_hud_client }
    created_by { association :hmis_user }
    value { Hmis::ScanCardCode.generate_code }
    created_at { Time.current }
    updated_at { Time.current }
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
