###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_access_control, class: 'Hmis::AccessControl' do
    role { association :hmis_role }
    access_group { association :hmis_access_group }
  end

  factory :hmis_user_access_control, class: 'Hmis::UserAccessControl' do
    user { association :hmis_user }
    access_control { association :hmis_access_control }
  end
end
