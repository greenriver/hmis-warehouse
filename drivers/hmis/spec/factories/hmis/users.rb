FactoryBot.define do
  factory :hmis_user, class: 'Hmis::User', parent: :user do
    first_name { 'Test' }
    last_name { 'User' }
  end
end
