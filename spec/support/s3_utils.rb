###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.configure do |config|
  config.before(:suite) do
    Aws.config.update(
      credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', 'local_access_key'), ENV.fetch('AWS_SECRET_ACCESS_KEY', 'local_secret_key')),
      endpoint: ENV.fetch('MINIO_ENDPOINT', 'http://s3.dev.test:9000'),
      force_path_style: true,
      region: 'us-east-1',
    )
  end
end

module S3Utils
  def create_bucket(name)
    Aws::S3::Bucket.new(name: name).create
  end

  def delete_bucket(name)
    bucket = Aws::S3::Bucket.new(name: name)
    bucket.objects.each(&:delete)
    bucket.delete
  end

  def get_s3_object(bucket:, key:)
    object = Aws::S3::Object.new(bucket_name: bucket, key: key)
    object.get
  end

  def put_s3_object(io:, bucket:, key:)
    object = Aws::S3::Object.new(bucket_name: bucket, key: key)
    object.upload_file(io)
  end
end
