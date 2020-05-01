FactoryBot.define do
  factory :accountable_care_organization, class: 'Health::AccountableCareOrganization' do
    name { 'Example ACO' }
    short_name { 'ACO' }
  end
end
