FactoryBot.define do
  # STI base class
  factory :grda_remote_oauth_credential, class: 'GrdaWarehouse::RemoteCredentials::Oauth' do
    # these are required by db schema
    active { true }
    sequence :username
    encrypted_password { SecureRandom.hex }
  end
end
