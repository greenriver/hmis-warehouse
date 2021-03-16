FactoryBot.define do
  factory :signable_careplan, class: 'Health::SignableDocument' do
    user_id { 1 }
    signable_type { Health::Careplan }
    signers { [{ email: 'patient@openpath.biz' }, { email: 'provider@openpath.biz' }] }
    signature_request { create :signature_request }
  end
end
