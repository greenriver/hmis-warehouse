###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
  end
end
