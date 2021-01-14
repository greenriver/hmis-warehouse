require 'faker'

FactoryBot.define do
  factory :patient, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referral
    association :client, factory: :hud_client
  end
end
