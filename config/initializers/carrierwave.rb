# Rails.logger.debug "Running initializer in #{__FILE__}"

CarrierWave.configure do |config|
  tmp_bucket = ENV['S3_TMP_BUCKET']
  tmp_access_key = ENV['S3_TMP_ACCESS_KEY_ID']
  tmp_secret_key = ENV['S3_TMP_ACCESS_KEY_SECRET']
  if tmp_bucket.present? && tmp_access_key.present? && tmp_secret_key.present?
    config.storage = :aws
    config.aws_acl  = 'private'
    config.aws_bucket = tmp_bucket

    config.aws_credentials = {
      access_key_id: tmp_access_key,
      secret_access_key: tmp_secret_key,
      region: ENV.fetch('S3_TMP_REGION'),
      stub_responses:    Rails.env.test?, # Optional, avoid hitting S3 actual during tests
    }
  end
end
