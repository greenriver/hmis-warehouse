FactoryBot.define do
  factory :patient_referral, class: 'Health::PatientReferral' do
    first_name { 'First' }
    last_name { 'Last' }
    birthdate { Date.today }
    sequence(:medicaid_id)
  end

  factory :patient, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referral
    sequence(:client_id)
  end
end
