FactoryBot.define do
  factory :patient_referral, class: 'Health::PatientReferral' do
    first_name { 'First' }
    last_name { 'Last' }
    birthdate { Date.current }
    sequence(:medicaid_id)
    enrollment_start_date { Date.current }
    current { true }
  end

  factory :prior_referral, class: 'Health::PatientReferral' do
    first_name { 'Patient' }
    last_name { 'A' }
    birthdate { Date.current }
    sequence(:medicaid_id)
    enrollment_start_date { Date.current - 1.year }
    disenrollment_date { Date.current - 11.months }
    current { false }
    contributing { false }
  end

  factory :contributing_referral, class: 'Health::PatientReferral' do
    first_name { 'Patient' }
    last_name { 'A' }
    birthdate { Date.current }
    sequence(:medicaid_id)
    enrollment_start_date { Date.current - 2.months }
    disenrollment_date { Date.current - 1.months }
    current { false }
    contributing { true }
  end

  factory :current_referral, class: 'Health::PatientReferral' do
    first_name { 'Patient' }
    last_name { 'A' }
    birthdate { Date.current }
    sequence(:medicaid_id)
    enrollment_start_date { Date.current - 2.weeks }
    current { true }
    contributing { true }
  end
end
