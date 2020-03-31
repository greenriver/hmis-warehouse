CarrierWave.configure do |config|
  tmp_bucket = ENV['S3_TMP_BUCKET']
  tmp_user = ENV['S3_TMP_ACCESS_KEY_ID']
  tmp_key = ENV['S3_TMP_ACCESS_KEY_SECRET']
  if tmp_bucket && tmp_user && tmp_key
    config.storage = :aws
    config.aws_acl  = 'private'
    config.aws_bucket = ENV.fetch('S3_TMP_BUCKET')

    config.aws_credentials = {
      access_key_id: ENV.fetch('S3_TMP_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('S3_TMP_ACCESS_KEY_SECRET'),
      region: ENV.fetch('S3_TMP_REGION'),
      stub_responses:    Rails.env.test?, # Optional, avoid hitting S3 actual during tests
    }
  end
end




