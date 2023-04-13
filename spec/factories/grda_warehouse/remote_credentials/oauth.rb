FactoryBot.define do
  factory :remote_token_credential, class: 'GrdaWarehouse::RemoteCredentials::Oauth' do
    sequence :slug

    # these are required by db schema
    active { true }
    sequence :username
    encrypted_password { SecureRandom.hex }
  end
end
