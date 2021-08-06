FactoryBot.define do
  factory :careplan, class: 'Health::Careplan' do
    provider_id { 1 }
    provider_signature_mode { :email }
  end
end
