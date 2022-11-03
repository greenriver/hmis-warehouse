FactoryBot.define do
  factory :view_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
    scope { 'view' }
  end

  factory :edit_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
    scope { 'edit' }
  end
end
