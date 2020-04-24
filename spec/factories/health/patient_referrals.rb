FactoryBot.define do
  factory :patient_referral, class: 'Health::PatientReferral' do
    first_name { 'First' }
    last_name { 'Last' }
    birthdate { Date.current }
    sequence(:medicaid_id)
    enrollment_start_date { Date.current }
    current { true }
  end
end
