###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-s3'
class AwsS3
  attr_accessor :region, :bucket_name, :access_key_id, :secret_access_key, :client
  attr_reader :bucket
  def initialize(
    region: nil,
    bucket_name:,
    access_key_id: nil,
    secret_access_key: nil,
    role_arn: nil,
    external_id: nil
  )
    @bucket_name = bucket_name

    region ||= ENV.fetch('AWS_REGION', 'us-east-1')

    client_options = {
      region: region,
    }

    # In development setup local access
    if ENV['USE_MINIO_ENDPOINT'] == 'true' && ENV['MINIO_ENDPOINT'].present?
      access_key_id = ENV['AWS_ACCESS_KEY_ID'] unless access_key_id.present?
      secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] unless secret_access_key.present?

      client_options = {
        force_path_style: true, # don't force dns hoop jumping
        endpoint: ENV.fetch('MINIO_ENDPOINT'),
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
      }
    else
      # if we are assuming a role, set that up
      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/AssumeRoleCredentials.html
      if role_arn.present?
        assume_options = {
          region: region,
          role_arn: role_arn,
          role_session_name: 'hmis-warehouse-session',
        }
        sts_options = {
          region: region,
        }
        assume_options[:external_id] = external_id if external_id.present?
        if secret_access_key.present? && secret_access_key != 'unknown'
          assume_options[:access_key_id] = access_key_id
          assume_options[:secret_access_key] = secret_access_key
          sts_options[:access_key_id] = access_key_id
          sts_options[:secret_access_key] = secret_access_key
        end
        assume_options[:client] = Aws::STS::Client.new(**sts_options)
        client_options[:credentials] = Aws::AssumeRoleCredentials.new(**assume_options)
      end
      # if we provided keys, use those
      if secret_access_key.present? && secret_access_key != 'unknown'
        client_options[:access_key_id] = access_key_id
        client_options[:secret_access_key] = secret_access_key
      end
    end

    self.client = Aws::S3::Client.new(**client_options)
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

  def list_objects(max_keys = 10_000, prefix: '')
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

    objects.
      sort_by(&:last_modified).
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

  def get_file_type(key:)
    @bucket.object(key)&.content_type
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

  def store(content:, name:, content_type: nil)
    obj = @bucket.object(name)
    args = { body: content }
    args.merge!(content_type: content_type) if content_type
    # we're skipping server side encryption for test and development because it hard to support in minio
    args.merge!(server_side_encryption: 'AES256') unless Rails.env.development? || Rails.env.test?
    obj.put(**args)
  end

  # Uploads all files from a local directory
  # @param directory_name [String] path to directory on local file system
  # @param prefix [String, nil] upload files under this prefix in the s3 bucket
  def upload_directory(directory_name:, prefix: nil)
    raise ArgumentError, 'Directory does not exist' unless Dir.exist?(directory_name)

    Dir.glob("#{directory_name}/*").each do |file|
      raise 'nested directories not supported' if File.directory?(file)

      put(file_name: file, prefix: prefix)
    end
  end

  def delete(key:)
    client.delete_object(bucket: bucket_name, key: key)
  end
end
