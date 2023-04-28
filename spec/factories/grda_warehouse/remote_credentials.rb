FactoryBot.define do
  factory :grda_remote_oauth_credential, class: 'GrdaWarehouse::RemoteCredential' do
    # these are required by db schema
    active { true }
    sequence :username
    encrypted_password { SecureRandom.hex }
  end
end
