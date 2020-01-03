###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'aws-sdk'
class AwsS3
  attr_accessor :region, :bucket_name, :access_key_id, :secret_access_key
  def initialize(
    region:,
    bucket_name:,
    access_key_id: nil,
    secret_access_key: nil
  )
    @region = region
    @bucket_name = bucket_name
    @access_key_id = access_key_id
    @secret_access_key = secret_access_key
    connect()
    @s3 = Aws::S3::Resource.new
    @bucket = @s3.bucket(@bucket_name)
  end

  def connect
    cred = Aws::Credentials.new(
      @access_key_id,
      @secret_access_key
    )
    if @secret_access_key.present? && @secret_access_key != 'unknown'
      Aws.config.update({
        region: @region,
        credentials: cred
      })
    else
       Aws.config.update({
        region: @region,
      })
    end
  end

  def exists?
    return @bucket.exists? rescue false
  end

  def list(prefix: '')
    return @bucket.objects(prefix: prefix).each do |obj|
      puts " #{obj.key} => #{obj.etag}"
    end
  end

  def fetch_key_list(prefix: '')
    @bucket.objects(prefix: prefix).map do |obj|
      obj.key
    end
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
