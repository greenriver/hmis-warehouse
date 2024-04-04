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

# FIX for CVE-2023-49090
raise unless Gem.loaded_specs['carrierwave'].version.to_s == '1.3.4'
module CarrierWave
  module Uploader
    module ContentTypeWhitelist
      private

      def whitelisted_content_type?(content_type)
        Array(content_type_whitelist).any? { |item| content_type =~ /\A#{item}/ }
      end
    end
  end
end
# FIX for CVE-2024-29034
CarrierWave::SanitizedFile.class_eval do
  def content_type
    return @content_type if @content_type
    if @file.respond_to?(:content_type) and @file.content_type
      @content_type = Marcel::MimeType.for(declared_type: @file.content_type.to_s.chomp)
    elsif path
      @content_type = ::MIME::Types.type_for(path).first.to_s
    end
  end
end
