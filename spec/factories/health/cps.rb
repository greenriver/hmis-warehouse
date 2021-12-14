FactoryBot.define do
  factory :sender, class: 'Health::Cp' do
    short_name { 'Sender' }
    sender { true }
    receiver_name { 'Test Receiver' }
    trace_id { 'OPENPATH00' }
  end

  factory :receiver, class: 'Health::Cp' do
    pid { '110999999' }
    sl { 'B' }
  end
end
