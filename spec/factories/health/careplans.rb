FactoryBot.define do
  factory :careplan, class: 'Health::Careplan' do
    provider_id { 1 }
    provider_signature_mode { :email }
  end

  factory :cp2_careplan, class: 'HealthPctp::Careplan' do
    association :user, factory: :user
    association :patient, factory: :patient
  end

  factory :pctp_careplan, class: 'Health::PctpCareplan' do
    association :instrument, factory: :cp2_careplan
  end
end
