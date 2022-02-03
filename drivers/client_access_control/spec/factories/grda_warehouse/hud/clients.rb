###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_source_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :vt_source_data_source
    sequence(:PersonalID, 10)
  end

  factory :vt_destination_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :vt_destination_data_source
    sequence(:PersonalID, 10)
  end
end
