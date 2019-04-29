FactoryBot.define do
  factory :sender, class: 'Health::Cp' do
    sender { true }
    receiver_name { 'Test Receiver' }
    trace_id { 'OPENPATH00' }
  end
end
