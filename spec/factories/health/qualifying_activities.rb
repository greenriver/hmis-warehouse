FactoryBot.define do
  factory :qa_source, class: 'Health::SdhCaseManagementNote' do
    title { 'SdhCaseManagementNote' }
    date_of_contact { '2023-03-31'.to_date }
    patient
    user
  end

  factory :qualifying_activity, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :in_person }
    reached_client { :yes }
    activity { :outreach }
    naturally_payable { true }
    association :source, factory: :qa_source
    user
    patient
  end

  factory :qualifying_activity_for_patient_a, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :in_person }
    reached_client { :yes }
    activity { :outreach }
    association :source, factory: :qa_source
    user
    association :patient
  end

  trait :old_qa do
    date_of_activity { '2023-03-31'.to_date - 10.months }
  end

  factory :valid_qa, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :in_person }
    reached_client { :yes }
    activity { :outreach }
    association :source, factory: :qa_source
    user
    patient
  end

  factory :pctp_signed_qa, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :other }
    mode_of_contact_other { 'X' }
    reached_client { :yes }
    activity { :pctp_signed }
    association :source, factory: :qa_source
    user
    patient
  end

  factory :cha_qa, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :other }
    mode_of_contact_other { 'X' }
    reached_client { :yes }
    activity { :cha }
    association :source, factory: :qa_source
    user
    patient
  end

  factory :discharge_follow_up_qa, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { '2023-03-31'.to_date }
    mode_of_contact { :other }
    mode_of_contact_other { 'X' }
    reached_client { :yes }
    activity { :discharge_follow_up }
    association :source, factory: :qa_source
    user
    patient
  end
end
