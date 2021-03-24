FactoryBot.define do
  factory :provider, class: 'Health::Team::Provider' do
    first_name { 'Dr' }
    last_name { 'Doctor' }
    email { 'provider@openpath.biz' }
    organization { 'OpenPath' }
  end
end
