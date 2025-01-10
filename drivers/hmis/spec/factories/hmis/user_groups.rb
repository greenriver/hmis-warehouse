###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_user_group, class: 'Hmis::UserGroup' do
    name { 'Test User Group' }
  end
end
