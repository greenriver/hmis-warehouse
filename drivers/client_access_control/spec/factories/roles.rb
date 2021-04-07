FactoryBot.define do
  factory :vt_role, class: 'Role' do
    name { 'role' }
  end
  factory :vt_can_view_clients, class: 'Role' do
    name { 'Visibility Test can view clients' }
    can_view_clients { true }
  end
end
