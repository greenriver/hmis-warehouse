###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_geography, class: 'GrdaWarehouse::Hud::Geography' do
    sequence(:ProjectID, 100)
    sequence(:GeographyID, 1)
  end

  factory :grda_warehouse_hud_geography, class: 'GrdaWarehouse::Hud::Geography' do
    data_source_id { 1 } # :data_source_fixed_id
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
