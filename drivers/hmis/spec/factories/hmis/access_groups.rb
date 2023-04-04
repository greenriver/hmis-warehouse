###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_role, class: 'Hmis::Role' do
    name { 'Test Role' }
    Hmis::Role.permissions_with_descriptions.keys.each do |perm|
      send(perm) { true }
    end
  end

  factory :hmis_role_with_no_permissions, class: 'Hmis::Role' do
    name { 'Test Role' }
  end

  factory :view_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
  end

  factory :edit_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
  end
end
