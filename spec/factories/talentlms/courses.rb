FactoryBot.define do
  factory :default_course, class: 'Talentlms::Course' do
    default { true }
    name { 'Default Course' }
  end
end
