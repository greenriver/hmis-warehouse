###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    Aws.config.update(
      credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', 'local_access_key'), ENV.fetch('AWS_SECRET_ACCESS_KEY', 'local_secret_key')),
      region: 'us-east-1',
      # Scoped to S3: :endpoint and :force_path_style are not members of other
      # services' config structs, and a global default raises when any non-S3
      # client is constructed in a spec.
      s3: {
        endpoint: ENV.fetch('LOCAL_S3_ENDPOINT', 'http://s3.dev.test:9000'),
        force_path_style: true,
      },
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
