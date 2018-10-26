FactoryGirl.define do
  factory :user do
    first_name 'Green'
    last_name 'River'
    sequence (:email) {|n| "user#{n}@greenriver.com"}
    # email 'green.river@mailinator.com'
    password Digest::SHA256.hexdigest('abcd1234abcd1234')
    password_confirmation Digest::SHA256.hexdigest('abcd1234abcd1234')
    confirmed_at Date.yesterday
    notify_on_vispdat_completed false
  end
end
