FactoryBot.define do
  factory :signature_request, class: 'Health::SignatureRequest' do
    patient_id { 1 }
    careplan_id { 1 }
    to_email { 'email@openpath.biz' }
    to_name { 'Signer' }
    requestor_email { 'email@openpath.biz' }
    requestor_name { 'Requestor' }
    expires_at { Time.current }
    type { 'Health::SignatureRequest' }
  end
end
