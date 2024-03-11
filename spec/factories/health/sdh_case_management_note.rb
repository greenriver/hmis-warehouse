FactoryBot.define do
  factory :sdh_case_management_note, class: 'Health::SdhCaseManagementNote' do
    user
    title { 'CM Note' }
    date_of_contact { Date.current }
    housing_status { 'Shelter' }
  end
end
