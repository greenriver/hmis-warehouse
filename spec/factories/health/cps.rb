FactoryBot.define do
  factory :sender, class: 'Health::Cp' do
    sender { true }
    receiver_name { 'Test Receiver' }
  end
end
