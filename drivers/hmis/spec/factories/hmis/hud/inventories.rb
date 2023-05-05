###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_inventory, class: 'Hmis::Hud::Inventory' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    project { association :hmis_hud_project, data_source: data_source }
    sequence(:InventoryID, 300)
    CoCCode { 'XX-500' }
    HouseholdType { 1 }
    Availability { 1 }
    sequence(:UnitInventory, 100)
    sequence(:BedInventory, 100)
    InventoryStartDate { '2020-12-01' }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
  end
end
