###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
class AwsS3
  attr_accessor :region, :bucket_name, :access_key_id, :secret_access_key, :client
  def initialize(
    region:,
    bucket_name:,
    access_key_id: nil,
    secret_access_key: nil
  )
    @bucket_name = bucket_name

    # if environment is set up right, this can all be:
    # self.client = Aws::S3::Client.new
    if secret_access_key.present? && secret_access_key != 'unknown'
      self.client = Aws::S3::Client.new({
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
      })
    else
      self.client = Aws::S3::Client.new({
        region: region,
      })
    end

    @s3 = Aws::S3::Resource.new(client: self.client)
    @bucket = @s3.bucket(@bucket_name)
  end

  def exists?
    return @bucket.exists? rescue false
  end

  def list(prefix: '')
    return @bucket.objects(prefix: prefix).each do |obj|
      puts " #{obj.key} => #{obj.etag}"
    end
  end

  # Return oldest first
  def fetch_key_list(prefix: '')
    @bucket.objects(prefix: prefix).sort_by(&:last_modified).map do |obj|
      obj.key
    end
  end

  def list_objects(max_keys=1_000, prefix: '')
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
    objects.sort_by(&:last_modified).
    reverse!&.
    first(max_keys)
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

  def put(file_name:, prefix:)
    name = "#{prefix}/#{File.basename(file_name)}"
    obj = @bucket.object(name)
    obj.upload_file(file_name, server_side_encryption: 'AES256')
  end

  def store(content:, name:)
    obj = @bucket.object(name)
    obj.put(body: content, server_side_encryption: 'AES256')
  end
end
