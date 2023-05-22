FactoryBot.define do
  factory :mhx_sftp_credentials, class: 'Health::ImportConfig' do
    host { 'sftp' }
    path { '/sftp' }
    username { 'user' }
    password { 'password' }
    kind { 'medicaid_hmis_exchange' }
    data_source_name { 'example@example.com' }
  end
end
