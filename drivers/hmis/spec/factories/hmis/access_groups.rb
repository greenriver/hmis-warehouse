FactoryBot.define do
  factory :hmis_role, class: 'Hmis::Role' do
    name { 'Test Role' }
    can_view_full_ssn { true }
    can_view_clients { true }
    can_administer_hmis { true }
    can_delete_assigned_project_data { true }
    can_delete_enrollments { true }
  end

  factory :view_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
    scope { 'view' }
  end

  factory :edit_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
    scope { 'edit' }
  end
end
