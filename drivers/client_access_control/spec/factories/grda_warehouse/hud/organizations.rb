###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_organization, class: 'GrdaWarehouse::Hud::Organization' do
    association :data_source, factory: :vt_source_data_source
    sequence(:OrganizationID, 200)
    sequence(:OrganizationName, 200) { |n| "Organization #{n}" }
  end
end
