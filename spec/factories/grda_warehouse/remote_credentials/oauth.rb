FactoryBot.define do
  factory :grda_remote_oauth_credential, class: 'GrdaWarehouse::RemoteCredentials::Oauth' do
    # these are required by db schema
    active { true }
    sequence :username
    encrypted_password { SecureRandom.hex }
    client_id { '1234567890' }
    client_secret { 'secretsecretsecret' }
    token_url { 'https://example.com/oauth2/v1/token' }
    oauth_scope { 'API_TEST' }
    base_url { 'https://example.com/api' }
  end
end
