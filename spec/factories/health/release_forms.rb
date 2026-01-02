# frozen_string_literal: true

FactoryBot.define do
  factory :release_form, class: 'Health::ReleaseForm' do
    association :patient, factory: :patient
    signature_on { Date.current - 30.days }
    participation_signature_on { Date.current - 29.days }
    mode_of_contact { 'in_person' }
    file_location { 'test_file.pdf' }

    trait :reviewed do
      association :reviewed_by, factory: :user
      reviewed_at { Date.current - 20.days }
    end
  end
end
