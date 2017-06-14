require 'aws-sdk-rails'
class AwsS3  
  def initialize
    # load bucket name from ENV
    @bucket_name = ENV["S3_BUCKET_NAME"]
    connect()
    @s3 = Aws::S3::Resource.new
    @bucket = @s3.bucket(@bucket_name)
  end
  
  def connect
    cred = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'], 
      ENV['AWS_SECRET_ACCESS_KEY']
    )
    Aws.config.update({
      region: ENV["AWS_REGION"], 
      credentials: cred
    })
  end
  
  def list(prefix: '')
    return @bucket.objects(prefix: prefix).limit(500).each do |obj|
      puts " #{obj.key} => #{obj.etag}"
    end
  end
  
  def fetch(file_name:, prefix:, target_path:)
    file = @bucket.object("#{prefix}/#{File.basename(file_name)}")
    file.get(response_target: target_path)
  end
  
  def put(file_name:, prefix:)
    name = "#{prefix}/#{File.basename(file_name)}"
    obj = @bucket.object(name)
    obj.upload_file(file_name, server_side_encryption: 'AES256')
  end 
end
