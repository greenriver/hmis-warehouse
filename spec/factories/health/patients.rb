FactoryBot.define do
  factory :patient, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referral
    association :client, factory: :hud_client
  end

  factory :patient_a, class: 'Health::Patient' do
    sequence(:id_in_source)
    patient_referrals { [create(:prior_referral), create(:contributing_referral), create(:current_referral)] }
    association :client, factory: :hud_client
  end
end
