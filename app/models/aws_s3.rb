###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
class AwsS3
  attr_accessor :region, :bucket_name, :access_key_id, :secret_access_key, :client
  def initialize(
    region: nil,
    bucket_name:,
    access_key_id: nil,
    secret_access_key: nil
  )
    @bucket_name = bucket_name

    region ||= ENV.fetch('AWS_REGION', 'us-east-1')

    # if environment is set up right, this can all be:
    # self.client = Aws::S3::Client.new
    if ENV['USE_MINIO_ENDPOINT'] == 'true' && ENV['MINIO_ENDPOINT'].present?
      access_key_id = ENV['AWS_ACCESS_KEY_ID'] unless access_key_id.present?
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] unless secret_access_key.present?

      params = {
        force_path_style: true, # don't force dns hoop jumping
        endpoint: ENV.fetch('MINIO_ENDPOINT'),
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
      }

      self.client = Aws::S3::Client.new(params)
    elsif secret_access_key.present? && secret_access_key != 'unknown'
      self.client = Aws::S3::Client.new(
        {
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
        },
      )
    else
      self.client = Aws::S3::Client.new(
        {
          region: region,
        },
      )
    end

    @s3 = Aws::S3::Resource.new(client: client)
    @bucket = @s3.bucket(@bucket_name)
  end

  def exists?
    return @bucket.exists?
  rescue StandardError
    false
  end

  def list(prefix: '')
    return @bucket.objects(prefix: prefix).each do |obj|
      puts " #{obj.key} => #{obj.etag}"
    end
  end

  # Return oldest first
  def fetch_key_list(prefix: '')
    @bucket.objects(prefix: prefix).sort_by(&:last_modified).map(&:key)
  end

  def list_objects(max_keys = 1_000, prefix: '')
    objects = []
    batch = client.list_objects_v2(
      {
        bucket: bucket_name,
        prefix: prefix,
      },
    )

    objects += batch.contents

    while batch.is_truncated
      batch = client.list_objects_v2(
        {
          bucket: bucket_name,
          prefix: prefix,
          start_after: batch.contents.last.key,
        },
      )

      objects += batch.contents
    end

    objects
      .sort_by(&:last_modified)
      .reverse!
      &.first(max_keys)
  end

  def fetch(file_name:, prefix: nil, target_path:)
    if prefix
      file_path = "#{prefix}/#{File.basename(file_name)}"
    else
      file_path = file_name
    end
    file = @bucket.object(file_path)
    file.get(response_target: target_path)
  end

  def get_as_io(key:)
    StringIO.new.tap do |result|
      @bucket.object(key).get(response_target: result)
    end
  end

  def put(file_name:, prefix:)
    name = "#{prefix}/#{File.basename(file_name)}"
    obj = @bucket.object(name)
    if Rails.env.development? || Rails.env.test?
      obj.upload_file(file_name)
    else
      obj.upload_file(file_name, server_side_encryption: 'AES256')
    end
  end

  def store(content:, name:)
    obj = @bucket.object(name)
    if Rails.env.development? || Rails.env.test?
      obj.put(body: content)
    else
      obj.put(body: content, server_side_encryption: 'AES256')
    end
  end
end
