FactoryBot.define do
  factory :qa_source, class: 'Health::SdhCaseManagementNote' do
    title { 'SdhCaseManagementNote' }
    date_of_contact { Date.current }
    patient
    user
  end

  factory :qualifying_activity, class: 'Health::QualifyingActivity' do
    user_full_name { 'First Last' }
    follow_up { 'X' }
    date_of_activity { Date.current }
    mode_of_contact { :in_person }
    reached_client { :yes }
    activity { :outreach }
    association :source, factory: :qa_source
    user
    patient
  end

  trait :old_qa do
    date_of_activity { Date.yesterday }
  end
end
