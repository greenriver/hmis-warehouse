FactoryBot.define do
  factory :user do
    first_name { 'Green' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    password { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    password_confirmation { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
  end

  factory :user_2fa, class: 'User' do
    first_name { 'Green2fa' }
    last_name { 'River' }
    sequence(:email) { |n| "user#{n}@greenriver.com" }
    # email 'green.river@mailinator.com'
    password { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    password_confirmation { Digest::SHA256.hexdigest('abcd1234abcd1234') }
    confirmed_at { Date.yesterday }
    notify_on_vispdat_completed { false }
    agency_id { 1 }
    otp_required_for_login { true }
    otp_secret { User.generate_otp_secret }
    confirmed_2fa { 2 }
  end
end
