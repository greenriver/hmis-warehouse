###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::S3Toolset
  extend ActiveSupport::Concern
  # Setup the S3 configuration if not setup if possible
  # Returns true if we're good to publish things, false if not
  def ready_public_s3_bucket!
    bucket_there = bucket_exists?
    website_there = bucket_website_configured?
    return true if bucket_there && website_there

    bucket_created = create_bucket! unless bucket_there
    return false unless bucket_created

    website_created = setup_bucket_website! unless website_there
    return false unless website_created

    # Check again to make sure it's all happy
    bucket_exists? && bucket_website_configured?
  end

  private def bucket_exists?
    s3_client.head_bucket(bucket: s3_bucket)
    return true
  rescue StandardError
    return false
  end

  private def create_bucket!
    response = s3_client.create_bucket(bucket: s3_bucket)
    return true if response.location == '/' + s3_bucket

    return false
  rescue StandardError => e
    Rails.logger.error("Error creating bucket: #{e.message}")
    return false
  end

  private def setup_bucket_website!
    s3_client.put_bucket_website(
      bucket: s3_bucket,
      website_configuration: {
        index_document: {
          suffix: 'index.html',
        },
      },
    )
    return true
  rescue StandardError => e
    Rails.logger.error("Error configuring bucket as a static website: #{e.message}")
    return false
  end

  private def bucket_website_configured?
    response = s3_client.get_bucket_website(bucket: s3_bucket)
    return true if response.index_document.present?
  rescue StandardError
    return false
  end

  private def s3_bucket
    ENV.fetch('S3_PUBLIC_BUCKET', "#{ENV.fetch('CLIENT').gsub('_', '-')}-#{Rails.env}-public")
  end

  private def s3_client
    @s3_client ||= if ENV['S3_PUBLIC_ACCESS_KEY_ID'].present? && ENV['S3_PUBLIC_ACCESS_KEY_SECRET'].present?
      Aws::S3::Client.new(
        access_key_id: ENV.fetch('S3_PUBLIC_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('S3_PUBLIC_ACCESS_KEY_SECRET'),
      )
    else
      Aws::S3::Client.new
    end
  end

  # NOTE: this is duplicated in 2 other reports that differ minimally
  private def push_to_s3
    bucket = s3_bucket
    prefix = public_s3_directory

    key = File.join(prefix, version_slug.to_s, 'index.html')
    resp = s3_client.put_object(
      acl: 'public-read',
      bucket: bucket,
      key: key,
      body: html,
      content_disposition: 'inline',
      content_type: 'text/html',
    )
    if resp.etag
      Rails.logger.info "Successfully uploaded report file to s3 (#{key})"
    else
      Rails.logger.info "Unable to upload report file (#{key}})"
    end
  end

  # NOTE: this is duplicated in 2 other reports that differ minimally
  private def remove_from_s3
    bucket = s3_bucket
    prefix = public_s3_directory
    key = File.join(prefix, version_slug.to_s, 'index.html')
    resp = s3_client.delete_object(
      bucket: bucket,
      key: key,
    )
    if resp.delete_marker
      Rails.logger.info "Successfully removed report file from s3 (#{key})"
    else
      Rails.logger.info "Unable to remove the report file (#{key})"
    end
  end
end
