FactoryGirl.define do
  factory :user do
    first_name 'Green'
    last_name 'River'
    email 'green.river@mailinator.com'
    password 'abcd1234'
    password_confirmation 'abcd1234'
    # reset_password_token
    # reset_password_sent_at
    # remember_created_at
    # sign_in_count
    # current_sign_in_at
    # last_sign_in_at
    # current_sign_in_ip
    # last_sign_in_ip
    # confirmation_token
    confirmed_at Date.yesterday 
    # confirmation_sent_at
    # unconfirmed_email
    # invitation_token
    # invitation_created_at
    # failed_attempts
    # unlock_token
    # locked_at
    # created_at
    # updated_at
    # deleted_at
    # invitation_sent_at
    # invitation_accepted_at
    # invitation_limit
    # invited_by_id
    # invited_by_type
    # invitations_count
  end
end
