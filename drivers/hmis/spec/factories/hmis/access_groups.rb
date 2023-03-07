FactoryBot.define do
  factory :hmis_role, class: 'Hmis::Role' do
    name { 'Test Role' }
    can_view_full_ssn { true }
    can_view_clients { true }
    can_administer_hmis { true }
    can_delete_assigned_project_data { true }
    can_delete_enrollments { true }
    can_delete_project { true }
    can_edit_project_details { true }
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
