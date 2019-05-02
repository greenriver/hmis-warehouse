FactoryBot.define do
  factory :patient, class: 'Health::Patient' do
    sequence(:id_in_source)
  end
end
