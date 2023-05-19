FactoryBot.define do
  factory :sender, class: 'Health::Cp' do
    pid { '110999999' }
    sl { 'B' }
    mmis_enrollment_name { 'SENDER' }
    short_name { 'Sender' }
    key_contact_first_name { '' }
    key_contact_last_name { '' }
    key_contact_phone { '9995551212' }
    sender { true }
    receiver_name { 'Test Receiver' }
    receiver_id { '123456789A' }
    trace_id { 'OPENPATH00' }
    npi { '987654321' }
    address_1 { '167 Main St' }
    city { 'Brattleboro' }
    state { 'VT' }
    zip { '05301' }
    ein { '999999999' }
  end

  factory :receiver, class: 'Health::Cp' do
    pid { '110999999' }
    sl { 'B' }
  end
end
