###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_organization, class: 'GrdaWarehouse::Hud::Organization' do
    sequence(:OrganizationID, 200)
    sequence(:OrganizationName, 200) { |n| "Organization #{n}" }
    association :data_source, factory: :grda_warehouse_data_source
  end

  factory :grda_warehouse_hud_organization, class: 'GrdaWarehouse::Hud::Organization' do
    data_source_id { 1 } # :data_source_fixed_id
    sequence(:OrganizationID, 200)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
