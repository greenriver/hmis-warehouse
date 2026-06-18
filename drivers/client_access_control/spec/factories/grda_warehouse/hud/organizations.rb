###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :vt_organization, class: 'GrdaWarehouse::Hud::Organization' do
    association :data_source, factory: :vt_source_data_source
    sequence(:OrganizationID, 200)
    sequence(:OrganizationName, 200) { |n| "Organization #{n}" }
  end
end
