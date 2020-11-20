FactoryBot.define do
  factory :accountable_care_organization, class: 'Health::AccountableCareOrganization' do
    name { 'Example ACO' }
    short_name { 'ACO' }
    edi_name { 'EXAMPLE ACO' }
    vpr_name { 'ACO Example' }
  end
end
