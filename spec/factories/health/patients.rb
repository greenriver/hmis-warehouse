FactoryBot.define do
  factory :patient, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referral
    sequence(:client_id)
  end
end
