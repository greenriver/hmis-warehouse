FactoryBot.define do
  factory :grda_remote_s3, class: 'GrdaWarehouse::RemoteCredentials::S3' do
    active { true }
    username { 'unknown' }
    password { 'unknown' }
    sequence(:bucket) { |n| "bucket#{n}" }
    sequence(:slug) { |n| "s3-#{n}" }
    region { 'us-east-1' }
    path { 'unknown' }
  end
end
