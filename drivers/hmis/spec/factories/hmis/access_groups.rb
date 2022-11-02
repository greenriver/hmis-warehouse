FactoryBot.define do
  factory :hmis_access_group, class: 'Hmis::AccessGroup' do
    sequence(:name) { |n| "Group #{n}" }
  end
end
