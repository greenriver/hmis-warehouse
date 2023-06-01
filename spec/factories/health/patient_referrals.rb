require 'faker'

FactoryBot.define do
  factory :patient_referral, class: 'Health::PatientReferral' do
    sequence(:medicaid_id, 100_000_000)
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { rand(18..64).years.ago + rand(365) }
    enrollment_start_date { Date.current }
    current { true }
    contributing { true }

    factory :prior_referral do
      enrollment_start_date { Date.current - 1.year }
      disenrollment_date { Date.current - 11.months }
      current { false }
      contributing { false }
    end

    factory :contributing_referral do
      enrollment_start_date { Date.current - 2.months }
      disenrollment_date { Date.current - 1.months }
      current { false }
      contributing { true }
    end

    factory :current_referral do
      enrollment_start_date { Date.current - 2.weeks }
      current { true }
      contributing { true }
    end
  end
end
