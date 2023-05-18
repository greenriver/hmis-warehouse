###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_user, class: 'Hmis::Hud::User' do
    data_source { association :hmis_data_source }
    sequence(:UserID) { |n| n + 500 }
    DateCreated { Time.now }
    DateUpdated { Time.now }
    sequence(:ExportID, 1)
  end
end
