FactoryBot.define do
  factory :grda_remote_oauth_credential, class: 'GrdaWarehouse::RemoteCredentials::Oauth' do
    # these are required by db schema
    active { true }
    client_id { SecureRandom.hex }
    client_secret { SecureRandom.hex }
    oauth_scope { 'API_TEST' }
    token_url { 'https://example.com/oauth2/v1/token' }
    base_url { 'https://example.com/api' }
  end
end
