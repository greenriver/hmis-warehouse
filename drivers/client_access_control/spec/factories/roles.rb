###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :vt_role, class: 'Role' do
    name { 'role' }
  end
  factory :vt_can_view_clients, class: 'Role' do
    name { 'Visibility Test can view clients' }
    can_view_clients { true }
  end
end
