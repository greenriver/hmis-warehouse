FactoryGirl.define do
  factory :user do
    first_name 'Green'
    last_name 'River'
    sequence (:email) {|n| "user#{n}@greenriver.com"}
    # email 'green.river@mailinator.com'
    password 'abcd1234'
    password_confirmation 'abcd1234'
    confirmed_at Date.yesterday
  end
end
